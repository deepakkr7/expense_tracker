import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/ocr_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/ocr_result_dialog.dart';

class ReceiptScanButton extends StatelessWidget {
  final Function(Map<String, dynamic>) onDataExtracted;

  const ReceiptScanButton({super.key, required this.onDataExtracted});

  Future<void> _scanReceipt(BuildContext context) async {
    try {
      // Show loading with proper constraints
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Material(
            color: Colors.transparent,
            child: CircularProgressIndicator(),
          ),
        ),
      );

      // Pick image from camera
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (!context.mounted) return;

      if (image == null) {
        // User cancelled
        Navigator.pop(context); // Close loading
        return;
      }

      // Extract data using OCR
      final ocrService = OCRService();
      final imageFile = File(image.path);
      final ocrData = await ocrService.extractReceiptData(imageFile);
      ocrService.dispose();

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // Show result dialog for review
      await showDialog(
        context: context,
        builder: (context) => OCRResultDialog(
          ocrData: ocrData,
          onApply: (editedData) {
            onDataExtracted(editedData);
          },
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading if still showing

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        onTap: () => _scanReceipt(context),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.document_scanner,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Receipt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-extract amount & details',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
