import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract data from a receipt image
  Future<Map<String, dynamic>> extractReceiptData(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final extractedData = parseReceiptText(recognizedText.text);
      return extractedData;
    } catch (e) {
      throw Exception('Failed to extract receipt data: $e');
    }
  }

  /// Parse receipt text and extract relevant information
  Map<String, dynamic> parseReceiptText(String text) {
    final Map<String, dynamic> data = {
      'rawText': text,
      'amount': extractAmount(text),
      'date': extractDate(text),
      'merchant': extractMerchant(text),
    };

    return data;
  }

  /// Extract amount from receipt text
  double? extractAmount(String text) {
    // Patterns to match amounts (₹, Rs., INR followed by numbers)
    final patterns = [
      RegExp(r'₹\s*(\d+(?:[,\.]\d+)?)', caseSensitive: false),
      RegExp(r'Rs\.?\s*(\d+(?:[,\.]\d+)?)', caseSensitive: false),
      RegExp(r'INR\s*(\d+(?:[,\.]\d+)?)', caseSensitive: false),
      RegExp(r'Total\s*[:\-]?\s*₹?\s*(\d+(?:[,\.]\d+)?)', caseSensitive: false),
      RegExp(
        r'Amount\s*[:\-]?\s*₹?\s*(\d+(?:[,\.]\d+)?)',
        caseSensitive: false,
      ),
      RegExp(r'Bill\s*[:\-]?\s*₹?\s*(\d+(?:[,\.]\d+)?)', caseSensitive: false),
    ];

    double? maxAmount;

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final amountStr = match.group(1)?.replaceAll(',', '');
          final amount = double.tryParse(amountStr ?? '');
          if (amount != null) {
            // Take the maximum amount found (likely to be the total)
            if (maxAmount == null || amount > maxAmount) {
              maxAmount = amount;
            }
          }
        }
      }
    }

    return maxAmount;
  }

  /// Extract date from receipt text
  DateTime? extractDate(String text) {
    // Common date patterns
    final patterns = [
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})'),
      // DD.MM.YYYY
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{2,4})'),
      // YYYY-MM-DD
      RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 3) {
        try {
          int day, month, year;

          // Check if it's YYYY-MM-DD format
          if (match.group(1)!.length == 4) {
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            // DD-MM-YYYY format
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);

            // Handle 2-digit year
            if (year < 100) {
              year += 2000;
            }
          }

          // Validate date
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  /// Extract merchant name from receipt text
  String? extractMerchant(String text) {
    // Try to find merchant name (usually in the first few lines)
    final lines = text.split('\n');

    // Take first non-empty line that's not a number or date
    for (var i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();

      // Skip empty lines, lines with only numbers, or very short lines
      if (line.isEmpty || line.length < 3) continue;
      if (RegExp(r'^[\d\s\-/:.]+$').hasMatch(line)) continue;

      // Check if it looks like a company name (contains letters and reasonable length)
      if (RegExp(r'[a-zA-Z]{3,}').hasMatch(line) && line.length <= 50) {
        return line;
      }
    }

    return null;
  }

  /// Dispose of the text recognizer
  void dispose() {
    _textRecognizer.close();
  }
}
