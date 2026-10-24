import '../models/payment_qr_data.dart';

class QRProcessorService {
  /// Process a QR code and extract payment information
  PaymentQRData processQR(String qrContent) {
    // Detect provider
    final provider = detectProvider(qrContent);

    // Parse UPI parameters
    final upiParams = parseUPIUrl(qrContent);

    // Extract merchant name
    final merchantName = upiParams['pn']; // Payee name

    // Extract amount
    double? amount;
    if (upiParams['am'] != null) {
      amount = double.tryParse(upiParams['am']!);
    }

    // Extract transaction note
    final transactionNote = upiParams['tn'];

    return PaymentQRData(
      provider: provider,
      merchantName: merchantName,
      amount: amount,
      transactionNote: transactionNote,
      originalUrl: qrContent,
      upiParams: upiParams,
    );
  }

  /// Detect the payment provider from the QR content
  PaymentProvider detectProvider(String qrContent) {
    final lowerContent = qrContent.toLowerCase();

    // Check for Paytm
    if (lowerContent.contains('paytm') ||
        lowerContent.startsWith('paytmmp://')) {
      return PaymentProvider.paytm;
    }

    // Check for PhonePe
    if (lowerContent.contains('phonepe') ||
        lowerContent.startsWith('phonepe://')) {
      return PaymentProvider.phonePe;
    }

    // Check for Google Pay
    if (lowerContent.contains('google.com/pay') ||
        lowerContent.contains('gpay') ||
        lowerContent.startsWith('gpay://')) {
      return PaymentProvider.gpay;
    }

    // Check if it's a UPI URL
    if (lowerContent.startsWith('upi://')) {
      return PaymentProvider.upi;
    }

    return PaymentProvider.unknown;
  }

  /// Parse UPI URL and extract parameters
  /// Format: upi://pay?pa=merchant@upi&pn=Merchant Name&am=100.00&tn=Payment note
  Map<String, String> parseUPIUrl(String url) {
    try {
      return Uri.parse(url).queryParameters;
    } catch (_) {
      return {};
    }
  }

  /// Generate app-specific payment URL
  String getPaymentAppUrl(String upiUrl, PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.gpay:
        if (!upiUrl.startsWith('gpay://')) {
          return 'gpay://$upiUrl';
        }
        return upiUrl;

      case PaymentProvider.phonePe:
        if (!upiUrl.startsWith('phonepe://')) {
          // Extract query parameters
          final params = parseUPIUrl(upiUrl);
          final queryString = params.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');
          return 'phonepe://pay?$queryString';
        }
        return upiUrl;

      case PaymentProvider.paytm:
        if (!upiUrl.startsWith('paytmmp://')) {
          final params = parseUPIUrl(upiUrl);
          final queryString = params.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');
          return 'paytmmp://pay?$queryString';
        }
        return upiUrl;

      case PaymentProvider.upi:
      case PaymentProvider.unknown:
        return upiUrl;
    }
  }
}
