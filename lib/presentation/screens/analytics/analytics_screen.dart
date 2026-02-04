import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/spending_line_chart.dart';
import '../../widgets/charts/budget_comparison_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      context.read<ExpenseProvider>().loadMonthlyExpenses(
        userId,
        _selectedMonth,
      );
      context.read<BudgetProvider>().loadBudget(userId, _selectedMonth);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    // Get data for current month
    final categoryTotals = expenseProvider.categoryTotals;
    final monthlyTotal = expenseProvider.monthlyTotal;

    // Get budget data
    final currentBudget = budgetProvider.currentBudget;

    // Prepare monthly trend data (last 6 months)
    final monthlyTrend = _getMonthlyTrend();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
            tooltip: 'Previous Month',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                DateFormat('MMM yyyy').format(_selectedMonth),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year
                ? null
                : () => _changeMonth(1),
            tooltip: 'Next Month',
          ),
        ],
      ),
      body: expenseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Spending Card
                  _buildTotalCard(monthlyTotal),
                  const SizedBox(height: 24),

                  // Category Distribution
                  _buildSectionTitle('Spending by Category'),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CategoryPieChart(
                            categoryTotals: categoryTotals,
                            totalAmount: monthlyTotal,
                          ),
                          const SizedBox(height: 16),
                          _buildLegend(categoryTotals),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Spending Trend
                  _buildSectionTitle('Spending Trend (Last 6 Months)'),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SpendingLineChart(monthlyData: monthlyTrend),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Budget Comparison
                  if (currentBudget != null) ...[
                    _buildSectionTitle('Budget vs Actual'),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            BudgetComparisonChart(
                              budgetAmounts: currentBudget.categoryBudgets,
                              actualAmounts: categoryTotals,
                            ),
                            const SizedBox(height: 16),
                            _buildBudgetLegend(),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Top Categories
                  const SizedBox(height: 24),
                  _buildSectionTitle('Top Categories'),
                  const SizedBox(height: 16),
                  _buildTopCategories(categoryTotals),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spending',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(Icons.show_chart, color: Colors.white, size: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildLegend(Map<String, double> categoryTotals) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categoryTotals.entries.map((entry) {
        final color = AppConstants.categoryColors[entry.key] ?? Colors.grey;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(entry.key, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBudgetLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Budget', AppTheme.primaryColor.withOpacity(0.3)),
        const SizedBox(width: 24),
        _buildLegendItem('Actual', AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTopCategories(Map<String, double> categoryTotals) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topThree = sortedCategories.take(3).toList();

    return Column(
      children: topThree.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final color = AppConstants.categoryColors[category.key] ?? Colors.grey;
        final icon = AppConstants.categoryIcons[category.key] ?? Icons.category;
        final percentage =
            (category.value / expenseProvider.monthlyTotal) * 100;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${index + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: color, size: 24),
                ],
              ),
            ),
            title: Text(
              category.key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${percentage.toStringAsFixed(1)}% of total',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Text(
              '₹${category.value.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<DateTime, double> _getMonthlyTrend() {
    final expenseProvider = context.watch<ExpenseProvider>();
    // This is a placeholder - in production, you'd load actual data
    // For now, returning dummy data for last 6 months
    final Map<DateTime, double> trend = {};
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);

      // If it's the current month, use actual data
      if (month.month == _selectedMonth.month &&
          month.year == _selectedMonth.year) {
        trend[month] = expenseProvider.monthlyTotal;
      } else {
        // Placeholder data for other months
        trend[month] = 0.0; // You could load this from Firestore
      }
    }

    return trend;
  }
}
