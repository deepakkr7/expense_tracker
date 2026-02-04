import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/borrowed_money_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  final _incomeController = TextEditingController();
  final _savingsController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};
  Map<String, double> _suggestedBudget = {};
  bool _showSuggestions = false;
  bool _isEditing = false;
  double _totalUnpaidDebt = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each category
    for (var category in AppConstants.expenseCategories) {
      _categoryControllers[category] = TextEditingController();
    }
    _loadUnpaidDebt();
  }

  void _loadUnpaidDebt() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      context.read<BorrowedMoneyProvider>().loadUnpaidBorrowedMoney(userId);
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generateSuggestions() {
    final income = double.tryParse(_incomeController.text);
    final savings = double.tryParse(_savingsController.text) ?? 0;

    if (income == null || income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid income')),
      );
      return;
    }

    // Get unpaid debt total
    final borrowedMoneyProvider = context.read<BorrowedMoneyProvider>();
    _totalUnpaidDebt = borrowedMoneyProvider.unpaidByPerson.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    final budgetProvider = context.read<BudgetProvider>();
    // Pass debt to budget generation
    budgetProvider.generateSuggestionsWithDebt(
      income,
      savings,
      _totalUnpaidDebt,
    );

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
    final income = double.tryParse(_incomeController.text) ?? 0;
    final savings = double.tryParse(_savingsController.text) ?? 0;

    if (income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid income')),
      );
      return;
    }

    // Update budget from controllers if in edit mode
    if (_isEditing) {
      _categoryControllers.forEach((category, controller) {
        final value = double.tryParse(controller.text);
        if (value != null && value >= 0) {
          _suggestedBudget[category] = value;
        }
      });
    }

    // Validate budget total
    final totalBudget = _suggestedBudget.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    final availableAmount = income - savings;

    if (totalBudget > availableAmount) {
      final excess = totalBudget - availableAmount;
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
                  'Budget Exceeds Income!',
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
                'Your total budget (₹${totalBudget.toStringAsFixed(0)}) exceeds your available amount (₹${availableAmount.toStringAsFixed(0)}) by ₹${excess.toStringAsFixed(0)}.',
              ),
              const SizedBox(height: 16),
              const Text(
                '💡 Suggestions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Reduce spending in some categories'),
              const Text('• Increase your monthly income'),
              const Text('• Lower your savings goal temporarily'),
              const SizedBox(height: 16),
              const Text(
                'Do you want to go back and adjust?',
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
    } else if (totalBudget < availableAmount) {
      // If there's any remaining balance, ask to add to savings
      final remaining = availableAmount - totalBudget;
      final addToSavings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.savings, color: AppTheme.successColor, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'You have a balance!',
                  style: TextStyle(color: AppTheme.successColor),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have ₹${remaining.toStringAsFixed(0)} remaining after your budget allocation.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '💰 Would you like to add this to your savings goal for this month?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current savings: ₹${savings.toStringAsFixed(0)}'),
                    Text(
                      'New savings: ₹${(savings + remaining).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No, Keep As Is'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.successColor,
              ),
              child: const Text('Yes, Add to Savings'),
            ),
          ],
        ),
      );

      if (addToSavings == true) {
        // Update savings goal with remaining amount
        final newSavings = savings + remaining;
        _savingsController.text = newSavings.toStringAsFixed(0);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Savings goal updated to ₹${newSavings.toStringAsFixed(0)}!',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }

        // Update the savings variable for the budget to be saved
        final updatedSavings = newSavings;

        // Save with updated savings
        await _saveBudgetWithSavings(
          authProvider,
          budgetProvider,
          income,
          updatedSavings,
        );
        return;
      }
    }

    await _saveBudgetWithSavings(authProvider, budgetProvider, income, savings);
  }

  Future<void> _saveBudgetWithSavings(
    AuthProvider authProvider,
    BudgetProvider budgetProvider,
    double income,
    double savingsGoal,
  ) async {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

    // Check if budget already exists for this month
    final existingBudget = await budgetProvider.getBudgetForMonth(
      authProvider.currentUser!.id,
      currentMonth,
    );

    if (existingBudget != null) {
      // Ask for confirmation to replace
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace Existing Budget?'),
          content: Text(
            'You already have a budget plan for ${DateFormat('MMMM yyyy').format(currentMonth)}. Do you want to replace it?',
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
      month: currentMonth,
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
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

    final budget = await budgetProvider.getBudgetForMonth(
      authProvider.currentUser!.id,
      currentMonth,
    );

    if (budget == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No budget plan for ${DateFormat('MMMM').format(currentMonth)} yet',
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
            '${DateFormat('MMMM yyyy').format(currentMonth)} Budget',
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
    final monthName = DateFormat('MMMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _viewCurrentBudget,
            tooltip: 'View Current Budget',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            // Income input
            TextFormField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Income',
                prefixText: '₹ ',
                hintText: '50000',
              ),
            ),
            const SizedBox(height: 16),

            // Savings input
            TextFormField(
              controller: _savingsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Savings Goal',
                prefixText: '₹ ',
                hintText: '10000',
              ),
            ),
            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generateSuggestions,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  'Generate Budget Plan',
                  style: TextStyle(fontSize: 16, color: Colors.white),
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
