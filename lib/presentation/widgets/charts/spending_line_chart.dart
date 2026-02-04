import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class SpendingLineChart extends StatelessWidget {
  final Map<DateTime, double> monthlyData;

  const SpendingLineChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const Center(child: Text('No spending trend data available'));
    }

    final sortedDates = monthlyData.keys.toList()..sort();
    final values = monthlyData.values.toList();
    final minY = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maxY = values.isEmpty
        ? 100.0
        : values.reduce((a, b) => a > b ? a : b);

    // Ensure we have a valid interval (prevent division by zero)
    final range = maxY - minY;
    final interval = range > 0 ? range / 5 : 20.0;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: LineChart(
          LineChartData(
            minY: minY * 0.9,
            maxY: maxY * 1.1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < sortedDates.length) {
                      final date = sortedDates[value.toInt()];
                      return Text(
                        DateFormat('MMM').format(date),
                        style: const TextStyle(fontSize: 10),
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
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _buildSpots(sortedDates),
                isCurved: true,
                color: AppTheme.primaryColor,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots(List<DateTime> sortedDates) {
    return List.generate(
      sortedDates.length,
      (index) => FlSpot(index.toDouble(), monthlyData[sortedDates[index]]!),
    );
  }
}
