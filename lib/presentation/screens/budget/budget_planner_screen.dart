import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/borrowed_money_provider.dart';
import '../../../providers/bill_reminder_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/bill_reminder_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  final Map<String, TextEditingController> _categoryControllers = {};
  Map<String, double> _suggestedBudget = {};
  bool _showSuggestions = false;
  bool _isEditing = false;
  bool _isGenerating = false;
  double _totalUnpaidDebt = 0.0;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    // Initialize controllers for each category
    for (var category in AppConstants.expenseCategories) {
      _categoryControllers[category] = TextEditingController();
    }
    _loadInitialData();
  }

  void _loadInitialData() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      context.read<BorrowedMoneyProvider>().loadUnpaidBorrowedMoney(userId);
      context.read<BillReminderProvider>().loadBills(userId);
    }
  }

  @override
  void dispose() {
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generateSuggestions() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null || user.savingsGoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your Monthly Limit in Profile first'),
        ),
      );
      return;
    }

    final limit = user.savingsGoal;
    final income = user.monthlyIncome;

    // Get unpaid debt total
    final borrowedMoneyProvider = context.read<BorrowedMoneyProvider>();
    _totalUnpaidDebt = borrowedMoneyProvider.unpaidByPerson.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    String debtStrategy = 'balanced';
    if (_totalUnpaidDebt > 0) {
      final selectedStrategy = await _showDebtStrategyDialog(_totalUnpaidDebt);
      if (selectedStrategy == null) return; // User cancelled the dialog
      debtStrategy = selectedStrategy;
    }

    setState(() {
      _isGenerating = true;
    });

    // Get unpaid bills and project recurring bills for the selected month
    final billProvider = context.read<BillReminderProvider>();
    Map<String, double> categoryBills = {};
    for (var bill in billProvider.bills) {
      if (!bill.isPaid) {
        if (bill.dueDate.month == _selectedMonth.month && bill.dueDate.year == _selectedMonth.year) {
          categoryBills[bill.category] = (categoryBills[bill.category] ?? 0.0) + bill.amount;
        } else if (bill.recurrenceType == RecurrenceType.monthly &&
            (bill.dueDate.isBefore(_selectedMonth) || (bill.dueDate.year == _selectedMonth.year && bill.dueDate.month < _selectedMonth.month))) {
          // Project recurring monthly bills that started before the selected month
          categoryBills[bill.category] = (categoryBills[bill.category] ?? 0.0) + bill.amount;
        }
      }
    }

    final budgetProvider = context.read<BudgetProvider>();
    
    try {
      await budgetProvider.generateSuggestionsWithDebt(
        income,
        limit, 
        _totalUnpaidDebt,
        categoryBills,
        debtStrategy,
      );

      if (mounted) {
        setState(() {
          _suggestedBudget = Map.from(budgetProvider.suggestedBudget);
          _showSuggestions = true;
          _isEditing = false;

          // Update text controllers with suggested values
          _suggestedBudget.forEach((category, amount) {
            _categoryControllers[category]?.text = amount.toStringAsFixed(0);
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<String?> _showDebtStrategyDialog(double totalDebt) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Debt Repayment Strategy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You have ₹${totalDebt.toStringAsFixed(0)} in Unpaid Debt. How would you like the AI to handle this?'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Aggressive'),
                subtitle: Text('Pay it off in full (₹${totalDebt.toStringAsFixed(0)})'),
                onTap: () => Navigator.pop(context, 'aggressive'),
                leading: const Icon(Icons.flash_on, color: AppTheme.warningColor),
              ),
              ListTile(
                title: const Text('Balanced'),
                subtitle: const Text('Let AI suggest a reasonable partial amount'),
                onTap: () => Navigator.pop(context, 'balanced'),
                leading: const Icon(Icons.balance, color: AppTheme.primaryColor),
              ),
              ListTile(
                title: const Text('Minimum'),
                subtitle: const Text('Pay minimum possible this month'),
                onTap: () => Navigator.pop(context, 'minimum'),
                leading: const Icon(Icons.arrow_downward, color: AppTheme.successColor),
              ),
            ],
          ),
        );
      }
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        // Populate controllers with current values
        _suggestedBudget.forEach((category, amount) {
          _categoryControllers[category]?.text = amount.toStringAsFixed(0);
        });
      } else {
        // Update suggested budget from controllers
        _categoryControllers.forEach((category, controller) {
          final value = double.tryParse(controller.text);
          if (value != null && value >= 0) {
            _suggestedBudget[category] = value;
          }
        });
      }
    });
  }

  Future<void> _saveBudget() async {
    final authProvider = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final user = authProvider.currentUser;

    if (user == null || user.savingsGoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your Monthly Limit in Profile'),
        ),
      );
      return;
    }

    final limit = user.savingsGoal;

    // Update budget from controllers if in edit mode
    if (_isEditing) {
      _categoryControllers.forEach((category, controller) {
        final value = double.tryParse(controller.text);
        if (value != null && value >= 0) {
          _suggestedBudget[category] = value;
        }
      });
    }

    // Validate budget total against limit
    final totalBudget = _suggestedBudget.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    if (totalBudget > limit) {
      final excess = totalBudget - limit;
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Budget Exceeds Limit!',
                  style: TextStyle(color: AppTheme.warningColor, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your total budget (₹${totalBudget.toStringAsFixed(0)}) exceeds your monthly limit (₹${limit.toStringAsFixed(0)}) by ₹${excess.toStringAsFixed(0)}.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Do you want to adjust your numbers or proceed anyway?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Anyway'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Go Back & Fix'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    await _saveBudgetWithSavings(
      authProvider,
      budgetProvider,
      user.monthlyIncome,
      limit,
    );
  }

  Future<void> _saveBudgetWithSavings(
    AuthProvider authProvider,
    BudgetProvider budgetProvider,
    double income,
    double savingsGoal,
  ) async {
    final targetMonth = _selectedMonth;

    // Check if budget already exists for this month
    final existingBudget = await budgetProvider.getBudgetForMonth(
      authProvider.currentUser!.id,
      targetMonth,
    );

    if (existingBudget != null) {
      // Ask for confirmation to replace
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace Existing Budget?'),
          content: Text(
            'You already have a budget plan for ${DateFormat('MMMM yyyy').format(targetMonth)}. Do you want to replace it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Replace'),
            ),
          ],
        ),
      );

      if (shouldReplace != true) return;

      // Delete the old budget first
      await budgetProvider.deleteBudget(
        authProvider.currentUser!.id,
        existingBudget.id,
      );
    }

    // Use existing budget ID if replacing, otherwise create new
    final budgetId = existingBudget?.id ?? const Uuid().v4();

    final budget = BudgetModel(
      id: budgetId,
      userId: authProvider.currentUser!.id,
      monthlyIncome: income,
      savingsGoal: savingsGoal,
      categoryBudgets: _suggestedBudget,
      month: targetMonth,
    );

    try {
      await budgetProvider.saveBudget(budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget saved successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reset the form
        setState(() {
          _showSuggestions = false;
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _viewCurrentBudget() async {
    final authProvider = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final targetMonth = _selectedMonth;

    final budget = await budgetProvider.getBudgetForMonth(
      authProvider.currentUser!.id,
      targetMonth,
    );

    if (budget == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No budget plan for ${DateFormat('MMMM').format(targetMonth)} yet',
            ),
          ),
        );
      }
      return;
    }

    // Show budget in dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            '${DateFormat('MMMM yyyy').format(targetMonth)} Budget',
            style: TextStyle(color: Colors.grey),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBudgetInfoRow('Monthly Income', budget.monthlyIncome),
                _buildBudgetInfoRow('Savings Goal', budget.savingsGoal),
                const Divider(height: 24),
                const Text(
                  'Category Budgets',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...budget.categoryBudgets.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          '₹${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBudgetInfoRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(_selectedMonth);
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final nextMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _viewCurrentBudget,
            tooltip: 'View Selected Month Budget',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Current Month'),
                  selected: _selectedMonth == currentMonth,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMonth = currentMonth;
                        _showSuggestions = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Next Month'),
                  selected: _selectedMonth == nextMonth,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMonth = nextMonth;
                        _showSuggestions = false;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create your $monthName budget plan',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Your Monthly Limit: ₹${context.read<AuthProvider>().currentUser?.savingsGoal.toStringAsFixed(0) ?? 0}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateSuggestions,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isGenerating ? 'AI is thinking...' : 'Generate AI Budget Plan',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ),

            // Suggested budget
            if (_showSuggestions) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget Breakdown',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  IconButton(
                    icon: Icon(_isEditing ? Icons.done : Icons.edit),
                    onPressed: _toggleEditMode,
                    color: AppTheme.primaryColor,
                    tooltip: _isEditing ? 'Done Editing' : 'Edit Budget',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ..._suggestedBudget.entries.map((entry) {
                final icon =
                    AppConstants.categoryIcons[entry.key] ?? Icons.category;
                final color =
                    AppConstants.categoryColors[entry.key] ?? Colors.grey;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    title: Text(entry.key),
                    trailing: _isEditing
                        ? SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _categoryControllers[entry.key],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: '₹ ',
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Text(
                            '₹${entry.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saveBudget,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Save Budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
