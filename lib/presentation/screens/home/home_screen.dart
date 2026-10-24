import '../onboarding/monthly_income_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../core/theme/app_theme.dart';

import '../../widgets/expense_card.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/monthly_review_bottom_sheet.dart';
import '../expense/all_expenses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _MonthlyLimitCard extends StatelessWidget {
  final double spent;
  final double limit;
  const _MonthlyLimitCard({required this.spent, required this.limit});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final remaining = ((1 - progress) * 100).round();
    final fmt = NumberFormat('#,##,###', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY LIMIT',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${fmt.format(spent)} / ₹${fmt.format(limit)}',
            style: TextStyle(
              color: colors.onSurface,
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
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining% Remaining',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
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
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MonthlyReviewBottomSheet(),
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Padding(
              padding: EdgeInsets.only(right: 16),
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
                        style: TextStyle(
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
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authProvider.currentUser != null &&
                  (authProvider.currentUser!.lastIncomeSetMonth?.month !=
                          DateTime.now().month ||
                      authProvider.currentUser!.lastIncomeSetMonth?.year !=
                          DateTime.now().year))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Review this month’s income'),
                        const Text(
                          'Update your income to keep your budget useful.',
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MonthlyIncomeScreen(),
                                ),
                              ),
                              child: const Text('Update income'),
                            ),
                            if (authProvider.currentUser!.monthlyIncome > 0)
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await authProvider.updateUser(
                                      authProvider.currentUser!.copyWith(
                                        lastIncomeSetMonth: DateTime.now(),
                                        incomeSetupCompleted: true,
                                      ),
                                    );
                                  } catch (_) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not save. Please try again.',
                                          ),
                                        ),
                                      );
                                  }
                                },
                                child: const Text('Use last month’s income'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              // Budget Alerts
              if (overBudgetCategories.isNotEmpty)
                ...overBudgetCategories.entries
                    .where((entry) => !_dismissedAlerts.contains(entry.key))
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
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
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF205B24), Color(0xFF246528)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [AppTheme.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹${user?.monthlyIncome.toStringAsFixed(0) ?? '0'}',
                              style: TextStyle(
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
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF9B1C1C), Color(0xFFAD2020)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [AppTheme.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹${monthlyTotal.toStringAsFixed(0)}',
                              style: TextStyle(
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
              SizedBox(height: 24),

              // Quick Actions Row removed

              // Live Limit Indicator
              if (user != null && user.savingsGoal > 0)
                _MonthlyLimitCard(spent: monthlyTotal, limit: user.savingsGoal),
              if (user != null && user.savingsGoal > 0) SizedBox(height: 24),

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
                        MaterialPageRoute(builder: (_) => AllExpensesScreen()),
                      );
                    },
                    child: Text('See All'),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Expenses List
              if (expenseProvider.isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (allExpenses.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
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
    );
  }
}
