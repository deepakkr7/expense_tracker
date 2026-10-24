import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/ocr_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/ocr_result_dialog.dart';

class ReceiptScanButton extends StatelessWidget {
  final Function(Map<String, dynamic>) onDataExtracted;

  const ReceiptScanButton({super.key, required this.onDataExtracted});

  Future<void> scanReceipt(BuildContext context) async {
    BuildContext? loadingContext;
    OCRService? service;
    void closeLoading() {
      if (loadingContext?.mounted == true) Navigator.pop(loadingContext!);
      loadingContext = null;
    }

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (!context.mounted || image == null) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          loadingContext = dialogContext;
          return const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
      service = OCRService();
      final data = await service.extractReceiptData(File(image.path));
      closeLoading();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) =>
            OCRResultDialog(ocrData: data, onApply: onDataExtracted),
      );
    } catch (_) {
      closeLoading();
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not scan the receipt. You can retry or enter the expense manually.',
            ),
          ),
        );
    } finally {
      service?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => scanReceipt(context),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.document_scanner,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Receipt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Auto-extract amount & details',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
