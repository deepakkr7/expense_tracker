import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalAmount;

  const CategoryPieChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No expense data available'));
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: _buildSections(),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final List<PieChartSectionData> sections = [];

    categoryTotals.forEach((category, amount) {
      final percentage = (amount / totalAmount) * 100;
      final color = AppConstants.categoryColors[category] ?? Colors.grey;

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return sections;
  }
}
