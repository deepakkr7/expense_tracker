import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _dismissedExpenseIds = {};
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

      expenseProvider.loadMonthlyExpenses(userId, now);
      expenseProvider.loadCategoryTotals(userId, now);
      budgetProvider.subscribeToBudget(userId, now);
    }
  }

  List<dynamic> _getTodayExpenses(List expenses) {
    final today = DateTime.now();
    return expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.year == today.year &&
          expenseDate.month == today.month &&
          expenseDate.day == today.day;
    }).toList();
  }

  double _getTodayTotal(List expenses) {
    return _getTodayExpenses(
      expenses,
    ).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    final user = authProvider.currentUser;
    final expenses = expenseProvider.expenses;
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

              // Monthly Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Month',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${monthlyTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expenses.length} transactions',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              // Quick Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Add Expense',
                      gradient: AppTheme.primaryGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddExpenseScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expanded(
                  //   child: _QuickActionButton(
                  //     icon: Icons.dashboard_customize_outlined,
                  //     label: 'Monthly Overview',
                  //     gradient: const LinearGradient(
                  //       colors: [AppTheme.successColor, Color(0xFF00B894)],
                  //     ),
                  //     onTap: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (_) => const MonthlyExpenseEntryScreen(),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Expenses Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.today, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s Expenses',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ],
                  ),
                  if (_getTodayExpenses(expenses).isNotEmpty)
                    Text(
                      '₹${_getTodayTotal(expenses).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_getTodayExpenses(expenses).isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No expenses today',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._getTodayExpenses(
                  expenses,
                ).where((expense) => !_dismissedExpenseIds.contains(expense.id)).map((
                  expense,
                ) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Dismissible(
                      key: ValueKey(
                        '${expense.id}_${expense.date.millisecondsSinceEpoch}',
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              'Delete Expense',
                              style: TextStyle(color: Colors.grey),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this expense?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        // Immediately mark as dismissed to prevent rebuild issues
                        setState(() {
                          _dismissedExpenseIds.add(expense.id);
                        });

                        try {
                          await expenseProvider.deleteExpense(
                            user!.id,
                            expense.id,
                          );
                          // Widget is automatically removed by stream update
                        } catch (e) {
                          // If error, remove from dismissed set
                          setState(() {
                            _dismissedExpenseIds.remove(expense.id);
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: ExpenseCard(expense: expense),
                    ),
                  );
                }).toList(),
              const SizedBox(height: 24),

              // Recent Expenses
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all expenses
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
              else if (expenses.isEmpty)
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
                          'No expenses yet',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...expenses
                    .take(10)
                    .map((expense) => ExpenseCard(expense: expense)),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
      //     );
      //   },
      //   icon: const Icon(Icons.add),
      //   label: const Text('Add Expense'),
      //   backgroundColor: AppTheme.primaryColor,
      // ),
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
