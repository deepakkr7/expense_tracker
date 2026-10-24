import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/payment_qr_data.dart';
import '../../core/theme/app_theme.dart';

class QRResultDialog extends StatefulWidget {
  final PaymentQRData qrData;
  final Future<bool> Function(Uri)? openPayment;

  const QRResultDialog({super.key, required this.qrData, this.openPayment});

  @override
  State<QRResultDialog> createState() => _QRResultDialogState();
}

class _QRResultDialogState extends State<QRResultDialog>
    with WidgetsBindingObserver {
  PaymentQRData get qrData => widget.qrData;
  bool _opened = false;
  bool _left = false;
  bool _asking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_opened && state == AppLifecycleState.paused) _left = true;
    if (_opened && _left && state == AppLifecycleState.resumed)
      _confirmPayment();
  }

  Future<void> _confirmPayment() async {
    if (_asking || !mounted) return;
    _asking = true;
    final completed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Did you complete payment?'),
        content: const Text(
          'Confirm only if your payment app shows success. You can review and save the expense next.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, review expense'),
          ),
        ],
      ),
    );
    _asking = false;
    _left = false;
    if (completed == true && mounted) Navigator.pop(context, qrData);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_opened)
              TextButton(
                onPressed: _confirmPayment,
                child: const Text('I completed payment — review expense'),
              ),
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
            SizedBox(height: 16),

            // Provider Name
            Text(
              qrData.providerName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            Text(
              'QR Code Detected',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),

            // Merchant Name
            if (qrData.merchantName != null) ...[
              _buildInfoRow(
                context,
                icon: Icons.store,
                label: 'Merchant',
                value: qrData.merchantName!,
              ),
              SizedBox(height: 12),
            ],

            // Amount
            if (qrData.amount != null) ...[
              _buildInfoRow(
                context,
                icon: Icons.currency_rupee,
                label: 'Amount',
                value: '₹${qrData.amount!.toStringAsFixed(2)}',
              ),
              SizedBox(height: 12),
            ],

            // Transaction Note
            if (qrData.transactionNote != null) ...[
              _buildInfoRow(
                context,
                icon: Icons.note,
                label: 'Note',
                value: qrData.transactionNote!,
              ),
              SizedBox(height: 12),
            ],

            // UPI ID
            if (qrData.upiParams['pa'] != null) ...[
              _buildInfoRow(
                context,
                icon: Icons.account_circle,
                label: 'UPI ID',
                value: qrData.upiParams['pa']!,
              ),
              SizedBox(height: 24),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPaymentApp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getProviderColor(),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(Icons.open_in_new, color: Colors.white),
                    label: Text(
                      'Open ${_getShortProviderName()}',
                      style: TextStyle(color: Colors.white),
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

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
        return Color(0xFF4285F4); // Google blue
      case PaymentProvider.phonePe:
        return Color(0xFF5F259F); // PhonePe purple
      case PaymentProvider.paytm:
        return Color(0xFF00B9F5); // Paytm blue
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
    if (_opened && _left) return;
    final address = qrData.upiParams['pa'];
    if (address == null || !address.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This QR code does not contain a valid UPI payment address.',
          ),
        ),
      );
      return;
    }
    final amount = qrData.upiParams['am'];
    if (amount != null &&
        (double.tryParse(amount) == null ||
            !double.parse(amount).isFinite ||
            double.parse(amount) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This QR code contains an invalid payment amount.'),
        ),
      );
      return;
    }
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: qrData.upiParams,
    );
    try {
      setState(() => _opened = true);
      final launched =
          await (widget.openPayment?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!launched && mounted) {
        setState(() => _opened = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Install a UPI payment app to continue.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _opened = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open a payment app. Please try again.'),
          ),
        );
      }
    }
  }
}
