import '../../../data/models/payment_qr_data.dart';
import '../expense/add_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/services/qr_processor_service.dart';
import '../../widgets/qr_scanner_overlay.dart';
import '../../widgets/qr_result_dialog.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;
  bool isTorchOn = false;
  final QRProcessorService _qrProcessor = QRProcessorService();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Process QR code
      final qrData = _qrProcessor.processQR(qrCode);

      // Show result dialog
      if (mounted) {
        await controller.stop();
        if (!mounted) return;
        final payment = await showDialog<PaymentQRData>(
          context: context,
          builder: (context) => QRResultDialog(qrData: qrData),
        );
        if (!mounted) return;
        if (payment != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                initialAmount:
                    payment.amount != null &&
                        payment.amount!.isFinite &&
                        payment.amount! > 0
                    ? payment.amount
                    : null,
                initialDescription:
                    payment.merchantName ??
                    payment.transactionNote ??
                    'UPI payment',
              ),
            ),
          );
        }
        if (mounted) await controller.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing QR: $e'),
            backgroundColor: Color(0xFFB3261E),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    await controller.toggleTorch();
    if (!mounted) return;
    setState(() {
      isTorchOn = !isTorchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: (capture) {
              if (isProcessing) return; // Skip if already processing

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // Show visual feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('QR Code detected! Processing...'),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                  _handleQRCode(barcode.rawValue!);
                  break; // Process only first valid code
                }
              }
            },
          ),

          // Custom overlay
          QRScannerOverlay(),

          // Top buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),

                  // Flash toggle
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 30,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
