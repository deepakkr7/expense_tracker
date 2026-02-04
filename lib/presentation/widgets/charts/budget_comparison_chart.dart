import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class BudgetComparisonChart extends StatelessWidget {
  final Map<String, double> budgetAmounts;
  final Map<String, double> actualAmounts;

  const BudgetComparisonChart({
    super.key,
    required this.budgetAmounts,
    required this.actualAmounts,
  });

  @override
  Widget build(BuildContext context) {
    if (budgetAmounts.isEmpty) {
      return const Center(child: Text('No budget data available'));
    }

    return AspectRatio(
      aspectRatio: 1.4,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _getMaxY(),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    final categories = budgetAmounts.keys.toList();
                    if (value.toInt() >= 0 &&
                        value.toInt() < categories.length) {
                      final category = categories[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppConstants.categoryIcons[category] ??
                                  Icons.category,
                              size: 16,
                              color: AppConstants.categoryColors[category],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _abbreviateCategory(category),
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '₹${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _buildBarGroups(),
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    budgetAmounts.forEach((key, value) {
      if (value > max) max = value;
    });
    actualAmounts.forEach((key, value) {
      if (value > max) max = value;
    });
    return max * 1.2;
  }

  List<BarChartGroupData> _buildBarGroups() {
    final categories = budgetAmounts.keys.toList();
    return List.generate(categories.length, (index) {
      final category = categories[index];
      final budget = budgetAmounts[category] ?? 0;
      final actual = actualAmounts[category] ?? 0;
      final color = AppConstants.categoryColors[category] ?? Colors.grey;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: budget,
            color: color.withOpacity(0.3),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: actual,
            color: actual > budget ? AppTheme.errorColor : color,
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  String _abbreviateCategory(String category) {
    if (category.length <= 8) return category;
    final words = category.split(' ');
    if (words.length > 1) {
      return words.map((w) => w[0]).join('.');
    }
    return category.substring(0, 6) + '..';
  }
}
