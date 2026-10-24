import 'dart:convert';
import 'backend_service.dart';
import 'privacy_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeepSeekService {
  Future<String> _complete(
    List<Map<String, String>> messages,
    double temperature,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (!await PrivacyPreferences.aiEnabled()) {
      throw Exception(
        'Enable optional AI assistance in More > Privacy & Account first.',
      );
    }
    if (uid == null || FirebaseAuth.instance.currentUser?.uid != uid) {
      throw Exception('Your session changed. Please try again.');
    }
    final result = await BackendService().call('ai', {
      'messages': messages,
      'temperature': temperature,
    });
    return result['content'] as String;
  }

  Future<Map<String, double>> generateBudgetPlan({
    required double income,
    required double limit,
    required double debt,
    required Map<String, double> bills,
    required List<String> categories,
    String debtStrategy = 'balanced',
  }) async {
    double totalBillsAmount = bills.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    double mandatoryDebt = 0.0;
    if (debt > 0 && debtStrategy == 'aggressive') {
      mandatoryDebt = debt;
    }

    double totalMandatory = totalBillsAmount + mandatoryDebt;
    double remaining = limit - totalMandatory;

    String limitInstruction = remaining < 0
        ? 'WARNING: The mandatory expenses (Bills + Debt) exceed the Target Limit (₹$limit). You MUST allocate the exact mandatory amounts, and set 0 for all others. The final total will exceed the Target Limit.'
        : 'CRITICAL RULE: The total sum of all categories MUST EXACTLY EQUAL the Target Savings Limit (₹$limit). After mandatory Bills and Debt, you only have exactly ₹$remaining remaining to distribute across the other categories. Do not exceed this limit!';

    String billsString = bills.isEmpty
        ? "None"
        : bills.entries
              .map((e) => "- ${e.key}: ₹${e.value.toStringAsFixed(0)}")
              .join('\n');

    String debtInstruction = '';
    if (debt > 0) {
      if (debtStrategy == 'aggressive') {
        debtInstruction =
            'You MUST allocate the FULL amount (₹$debt) to "Debt Repayment". Do not reduce this amount.';
      } else if (debtStrategy == 'balanced') {
        debtInstruction =
            'Allocate a reasonable partial amount to "Debt Repayment" to balance with other expenses.';
      } else {
        debtInstruction =
            'Allocate only a very small minimum amount or 0 to "Debt Repayment" so the user can prioritize other expenses.';
      }
    }

    final prompt =
        '''
You are a financial advisor AI. The user needs a monthly budget plan.
Income: ₹$income
Target Savings Limit (Max to spend): ₹$limit
Unpaid Debt (Borrowed Money): ₹$debt
Upcoming Bills this month:
$billsString
Categories available: ${categories.join(', ')}

Please distribute the budget across these categories. $limitInstruction
If Upcoming Bills are listed, you MUST allocate AT LEAST the specified amounts to their corresponding categories.
$debtInstruction
Return the response strictly as a valid JSON object where keys are category names (exactly as provided) and values are numerical amounts (no currency symbols or commas). Do not include markdown code blocks, just raw JSON.
Example: {"Food & Dining": 5000, "Transport": 2000}
''';

    final content = await _complete([
      {'role': 'user', 'content': prompt},
    ], 0.2);
    final cleaned = content
        .trim()
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    final result = <String, double>{};
    for (final entry in parsed.entries) {
      final value = entry.value;
      if (!categories.contains(entry.key) ||
          value is! num ||
          !value.isFinite ||
          value < 0) {
        throw const FormatException('Invalid AI budget response');
      }
      result[entry.key] = value.toDouble();
    }
    if (result.isEmpty) throw const FormatException('Empty AI budget response');
    return result;
  }

  Future<String?> categorizeExpense(
    String description,
    List<String> categories,
  ) async {
    if (!await PrivacyPreferences.aiEnabled()) return null;
    try {
      final content = (await _complete([
        {
          'role': 'user',
          'content':
              'Return only one category from: ${categories.join(', ')}. Expense: $description',
        },
      ], 0.1)).trim();
      return categories.contains(content) ? content : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> chatWithSavingsCoach(
    List<Map<String, String>> conversationHistory,
  ) {
    return _complete(conversationHistory, 0.7);
  }
}
