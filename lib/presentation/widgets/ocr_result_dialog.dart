import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OCRResultDialog extends StatefulWidget {
  final Map<String, dynamic> ocrData;
  final Function(Map<String, dynamic>) onApply;

  const OCRResultDialog({
    super.key,
    required this.ocrData,
    required this.onApply,
  });

  @override
  State<OCRResultDialog> createState() => _OCRResultDialogState();
}

class _OCRResultDialogState extends State<OCRResultDialog> {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.ocrData['amount']?.toString() ?? '',
    );
    _merchantController = TextEditingController(
      text: widget.ocrData['merchant'] ?? '',
    );
    _dateController = TextEditingController(
      text: widget.ocrData['date']?.toString().split(' ')[0] ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _applyData() {
    final data = {
      'amount': double.tryParse(_amountController.text),
      'merchant': _merchantController.text.isNotEmpty
          ? _merchantController.text
          : null,
      'date': _dateController.text.isNotEmpty ? _dateController.text : null,
    };
    widget.onApply(data);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Data Extracted',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Review and edit if needed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Amount field
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              SizedBox(height: 16),

              // Merchant field
              TextField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: 'Merchant/Store',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              SizedBox(height: 16),

              // Date field
              TextField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              SizedBox(height: 24),

              // Confidence Notice
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OCR may not be 100% accurate. Please verify.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _applyData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(Icons.check, color: Colors.white),
                      label: Text(
                        'Apply Data',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
