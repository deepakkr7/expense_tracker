import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AlertBanner extends StatelessWidget {
  final String category;
  final double percentage;
  final VoidCallback? onDismiss;

  const AlertBanner({
    super.key,
    required this.category,
    required this.percentage,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isOverBudget = percentage >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverBudget
            ? AppTheme.errorColor.withOpacity(0.1)
            : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverBudget ? AppTheme.errorColor : AppTheme.warningColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverBudget ? Icons.error_outline : Icons.warning_amber,
            color: isOverBudget ? AppTheme.errorColor : AppTheme.warningColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverBudget
                      ? '$category budget exceeded!'
                      : '$category budget warning',
                  style: TextStyle(
                    color: isOverBudget
                        ? AppTheme.errorColor
                        : AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve spent ${(percentage * 100).toStringAsFixed(0)}% of your budget',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: isOverBudget ? AppTheme.errorColor : AppTheme.warningColor,
              tooltip: 'Dismiss',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
