import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/payment_qr_data.dart';
import '../../core/theme/app_theme.dart';

class QRResultDialog extends StatelessWidget {
  final PaymentQRData qrData;

  const QRResultDialog({super.key, required this.qrData});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Provider Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getProviderColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getProviderIcon(),
                size: 40,
                color: _getProviderColor(),
              ),
            ),
            const SizedBox(height: 16),

            // Provider Name
            Text(
              qrData.providerName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              'QR Code Detected',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Merchant Name
            if (qrData.merchantName != null) ...[
              _buildInfoRow(
                icon: Icons.store,
                label: 'Merchant',
                value: qrData.merchantName!,
              ),
              const SizedBox(height: 12),
            ],

            // Amount
            if (qrData.amount != null) ...[
              _buildInfoRow(
                icon: Icons.currency_rupee,
                label: 'Amount',
                value: '₹${qrData.amount!.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
            ],

            // Transaction Note
            if (qrData.transactionNote != null) ...[
              _buildInfoRow(
                icon: Icons.note,
                label: 'Note',
                value: qrData.transactionNote!,
              ),
              const SizedBox(height: 12),
            ],

            // UPI ID
            if (qrData.upiParams['pa'] != null) ...[
              _buildInfoRow(
                icon: Icons.account_circle,
                label: 'UPI ID',
                value: qrData.upiParams['pa']!,
              ),
              const SizedBox(height: 24),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPaymentApp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getProviderColor(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    label: Text(
                      'Open ${_getShortProviderName()}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProviderColor() {
    switch (qrData.provider) {
      case PaymentProvider.gpay:
        return const Color(0xFF4285F4); // Google blue
      case PaymentProvider.phonePe:
        return const Color(0xFF5F259F); // PhonePe purple
      case PaymentProvider.paytm:
        return const Color(0xFF00B9F5); // Paytm blue
      case PaymentProvider.upi:
        return AppTheme.primaryColor;
      case PaymentProvider.unknown:
        return Colors.grey;
    }
  }

  IconData _getProviderIcon() {
    switch (qrData.provider) {
      case PaymentProvider.gpay:
        return Icons.account_balance_wallet;
      case PaymentProvider.phonePe:
        return Icons.phone_android;
      case PaymentProvider.paytm:
        return Icons.payment;
      case PaymentProvider.upi:
        return Icons.qr_code_2;
      case PaymentProvider.unknown:
        return Icons.help_outline;
    }
  }

  String _getShortProviderName() {
    switch (qrData.provider) {
      case PaymentProvider.gpay:
        return 'GPay';
      case PaymentProvider.phonePe:
        return 'PhonePe';
      case PaymentProvider.paytm:
        return 'Paytm';
      case PaymentProvider.upi:
        return 'UPI App';
      case PaymentProvider.unknown:
        return 'App';
    }
  }

  Future<void> _openPaymentApp(BuildContext context) async {
    String url = qrData.originalUrl;

    try {
      // For generic UPI, convert to Android Intent format
      if (qrData.provider == PaymentProvider.upi) {
        // Android Intent URL format for UPI
        url =
            'intent://$url#Intent;scheme=upi;package=com.google.android.apps.nbu.paisa.user;end';
      } else if (qrData.providerAppUrl != null) {
        url = qrData.providerAppUrl!;
      }

      final uri = Uri.parse(url);

      // Try to launch with different modes based on provider
      if (qrData.provider == PaymentProvider.upi) {
        // For UPI, try external application mode first
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && context.mounted) {
          // If that fails, show list of UPI apps
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please install a UPI app (GPay, PhonePe, Paytm, etc.)',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        // For specific providers
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (context.mounted) {
            Navigator.pop(context);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${qrData.providerName} app not installed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
