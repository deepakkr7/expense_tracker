import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class MonthlyExpenseEntryScreen extends StatefulWidget {
  const MonthlyExpenseEntryScreen({super.key});

  @override
  State<MonthlyExpenseEntryScreen> createState() =>
      _MonthlyExpenseEntryScreenState();
}

class _MonthlyExpenseEntryScreenState extends State<MonthlyExpenseEntryScreen> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    // Defer loading until after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthData();
    });
  }

  void _loadMonthData() {
    final authProvider = context.read<AuthProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    if (authProvider.currentUser != null) {
      expenseProvider.loadMonthlyExpenses(
        authProvider.currentUser!.id,
        _selectedMonth,
      );
      budgetProvider.loadBudget(authProvider.currentUser!.id, _selectedMonth);
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
      _loadMonthData();
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
      _loadMonthData();
    });
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final categoryTotals = expenseProvider.categoryTotals;
    final monthlyTotal = expenseProvider.monthlyTotal;
    final budget = budgetProvider.currentBudget;
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Overview', style: TextStyle(fontSize: 16)),
            Text(
              monthName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          // Previous Month
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: 'Previous Month',
          ),
          // Current Month Indicator
          if (!_isCurrentMonth())
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    1,
                  );
                  _loadMonthData();
                });
              },
              child: const Text('Today', style: TextStyle(fontSize: 12)),
            ),
          // Next Month (disabled if current or future)
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isCurrentMonth() ? null : _nextMonth,
            tooltip: 'Next Month',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    'Total Expenses',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${monthlyTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (budget != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Budget: ₹${budget.categoryBudgets.values.fold(0.0, (sum, val) => sum + val).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Breakdown Header
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),

            // Category Cards
            if (categoryTotals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses this month',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start adding expenses to see breakdown',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...AppConstants.expenseCategories.map((category) {
                final spent = categoryTotals[category] ?? 0.0;
                final budgetAmount = budget?.categoryBudgets[category] ?? 0.0;
                final percentage = budgetAmount > 0
                    ? (spent / budgetAmount)
                    : 0.0;
                final icon =
                    AppConstants.categoryIcons[category] ?? Icons.category;
                final color =
                    AppConstants.categoryColors[category] ?? Colors.grey;

                // Only show categories with expenses or budget
                if (spent == 0 && budgetAmount == 0) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (budgetAmount > 0)
                                    Text(
                                      'Budget: ₹${budgetAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${spent.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: percentage > 1.0
                                        ? AppTheme.errorColor
                                        : percentage > 0.8
                                        ? AppTheme.warningColor
                                        : AppTheme.successColor,
                                  ),
                                ),
                                if (budgetAmount > 0)
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: percentage > 1.0
                                          ? AppTheme.errorColor
                                          : percentage > 0.8
                                          ? AppTheme.warningColor
                                          : Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (budgetAmount > 0) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage > 1.0 ? 1.0 : percentage,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage > 1.0
                                    ? AppTheme.errorColor
                                    : percentage > 0.8
                                    ? AppTheme.warningColor
                                    : AppTheme.successColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                percentage > 1.0
                                    ? 'Over budget!'
                                    : percentage > 0.8
                                    ? 'Near limit'
                                    : 'On track',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: percentage > 1.0
                                      ? AppTheme.errorColor
                                      : percentage > 0.8
                                      ? AppTheme.warningColor
                                      : AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Remaining: ₹${(budgetAmount - spent).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
