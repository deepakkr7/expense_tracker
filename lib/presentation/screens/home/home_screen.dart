import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../expense/add_expense_screen.dart';
import '../budget/budget_planner_screen.dart';
import '../budget/monthly_expense_entry_screen.dart';
import '../analytics/analytics_screen.dart';
import '../borrowed_money/borrowed_money_screen.dart';
import '../bill_reminders/bill_reminders_screen.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/monthly_review_bottom_sheet.dart';
import '../expense/all_expenses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _dismissedAlerts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkMonthlyReview();
  }

  void _checkMonthlyReview() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return;

    final now = DateTime.now();
    // Check if it's the last 5 days of the month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final isEndOfMonth = now.day >= daysInMonth - 4;

    if (!isEndOfMonth) return;

    // Check if review was already done this month
    if (user.lastMonthReviewCompleted != null) {
      final lastReview = user.lastMonthReviewCompleted!;
      // If reviewed in current month, don't show again
      if (lastReview.year == now.year && lastReview.month == now.month) {
        return;
      }
    }

    // Show review bottom sheet after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const MonthlyReviewBottomSheet(),
        );
      }
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;
      final now = DateTime.now();

      expenseProvider.loadUserExpenses(userId);
      expenseProvider.loadMonthlyExpenses(userId, now);
      expenseProvider.loadCategoryTotals(userId, now);
      budgetProvider.subscribeToBudget(userId, now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    final user = authProvider.currentUser;
    final allExpenses = expenseProvider.allExpenses;
    final monthlyTotal = expenseProvider.monthlyTotal;
    final categoryTotals = expenseProvider.categoryTotals;
    final overBudgetCategories = budgetProvider.getOverBudgetCategories(
      categoryTotals,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hi, ${user?.name ?? 'User'}!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundImage:
                    user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                backgroundColor: AppTheme.primaryColor,
                child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                    ? Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget Alerts
              if (overBudgetCategories.isNotEmpty)
                ...overBudgetCategories.entries
                    .where((entry) => !_dismissedAlerts.contains(entry.key))
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AlertBanner(
                          category: entry.key,
                          percentage: entry.value,
                          onDismiss: () {
                            setState(() {
                              _dismissedAlerts.add(entry.key);
                            });
                          },
                        ),
                      ),
                    ),

              // Monthly Summary Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [AppTheme.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Income',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹${user?.monthlyIncome.toStringAsFixed(0) ?? '0'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC62828), Color(0xFFEF5350)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [AppTheme.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expenses',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹${monthlyTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Row removed

              // Live Limit Indicator
              if (user != null && user.savingsGoal > 0)
                _MonthlyLimitCard(spent: monthlyTotal, limit: user.savingsGoal),
              if (user != null && user.savingsGoal > 0)
                const SizedBox(height: 24),

              // Recent Expenses
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllExpensesScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Expenses List
              if (expenseProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (allExpenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...allExpenses
                    .take(10)
                    .map((expense) => ExpenseCard(expense: expense)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionBottomSheet(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTransactionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddTransactionBottomSheet(),
    );
  }
}

class _AddTransactionBottomSheet extends StatelessWidget {
  const _AddTransactionBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Expense'),
                Tab(text: 'Income'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const AddExpenseScreen(isBottomSheet: true),
                  _IncomeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeTab extends StatefulWidget {
  @override
  State<_IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<_IncomeTab> {
  final _amountController = TextEditingController();
  final _typeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      if (user != null) {
        final currentIncome = user.monthlyIncome;
        final updatedIncome = currentIncome + amount;
        final updatedUser = user.copyWith(monthlyIncome: updatedIncome);
        await authProvider.updateUser(updatedUser);

        final title = _typeController.text.trim().isNotEmpty
            ? _typeController.text.trim()
            : 'Income';
        final incomeTransaction = ExpenseModel(
          id: const Uuid().v4(),
          userId: user.id,
          amount: amount,
          category: 'Income',
          description: title,
          date: DateTime.now(),
          isIncome: true,
        );

        await context.read<ExpenseProvider>().addExpense(incomeTransaction);

        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title saved')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Income Amount *',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _typeController,
            decoration: const InputDecoration(
              labelText: 'Income Type',
              hintText: 'e.g. Salary, Freelance, Bonus',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveIncome,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Income',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyLimitCard extends StatelessWidget {
  final double spent;
  final double limit;

  const _MonthlyLimitCard({required this.spent, required this.limit});

  @override
  Widget build(BuildContext context) {
    final progress = (limit > 0) ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final remaining = ((1 - progress) * 100).round();
    final fmt = NumberFormat('#,##,###', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTHLY LIMIT',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${fmt.format(spent)} / ₹${fmt.format(limit)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFF374151),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining% Remaining',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
