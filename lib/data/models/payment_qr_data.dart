enum PaymentProvider {
  gpay,
  phonePe,
  paytm,
  upi, // Generic UPI
  unknown,
}

class PaymentQRData {
  final PaymentProvider provider;
  final String? merchantName;
  final double? amount;
  final String? transactionNote;
  final String originalUrl;
  final Map<String, String> upiParams;

  const PaymentQRData({
    required this.provider,
    this.merchantName,
    this.amount,
    this.transactionNote,
    required this.originalUrl,
    required this.upiParams,
  });

  String get providerName {
    switch (provider) {
      case PaymentProvider.gpay:
        return 'Google Pay';
      case PaymentProvider.phonePe:
        return 'PhonePe';
      case PaymentProvider.paytm:
        return 'Paytm';
      case PaymentProvider.upi:
        return 'UPI';
      case PaymentProvider.unknown:
        return 'Unknown';
    }
  }

  String? get providerAppUrl {
    final baseUrl = originalUrl;

    switch (provider) {
      case PaymentProvider.gpay:
        // Google Pay deep link
        if (!baseUrl.startsWith('gpay://')) {
          return 'gpay://$baseUrl';
        }
        return baseUrl;
      case PaymentProvider.phonePe:
        // PhonePe deep link
        if (!baseUrl.startsWith('phonepe://')) {
          return 'phonepe://pay?$baseUrl';
        }
        return baseUrl;
      case PaymentProvider.paytm:
        // Paytm deep link
        if (!baseUrl.startsWith('paytmmp://')) {
          return 'paytmmp://pay?$baseUrl';
        }
        return baseUrl;
      case PaymentProvider.upi:
      case PaymentProvider.unknown:
        // Generic UPI URL
        return baseUrl;
    }
  }
}
