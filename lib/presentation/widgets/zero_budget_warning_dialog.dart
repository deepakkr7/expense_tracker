import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ZeroBudgetWarningDialog extends StatelessWidget {
  final String category;
  final double amount;
  final VoidCallback onIgnoreAndContinue;

  const ZeroBudgetWarningDialog({
    super.key,
    required this.category,
    required this.amount,
    required this.onIgnoreAndContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
      title: const Text(
        'Zero Budget Alert',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are spending ₹${amount.toStringAsFixed(0)} on "$category" which has ₹0 budget allocation.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consider allocating budget for this category or adjust your spending.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
            onIgnoreAndContinue();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text(
            'Ignore & Continue',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
