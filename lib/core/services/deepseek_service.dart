import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  Future<Map<String, double>> generateBudgetPlan({
    required double income,
    required double limit,
    required double debt,
    required Map<String, double> bills,
    required List<String> categories,
    String debtStrategy = 'balanced',
  }) async {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('DeepSeek API key not found in .env');
    }

    double totalBillsAmount = bills.values.fold(0.0, (sum, amount) => sum + amount);
    
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
        : bills.entries.map((e) => "- ${e.key}: ₹${e.value.toStringAsFixed(0)}").join('\n');

    String debtInstruction = '';
    if (debt > 0) {
      if (debtStrategy == 'aggressive') {
        debtInstruction = 'You MUST allocate the FULL amount (₹$debt) to "Debt Repayment". Do not reduce this amount.';
      } else if (debtStrategy == 'balanced') {
        debtInstruction = 'Allocate a reasonable partial amount to "Debt Repayment" to balance with other expenses.';
      } else {
        debtInstruction = 'Allocate only a very small minimum amount or 0 to "Debt Repayment" so the user can prioritize other expenses.';
      }
    }

    final prompt = '''
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

    print('--- DEEPSEEK AI PROMPT ---');
    print(prompt);
    print('--------------------------');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a strict JSON-only financial assistant. You only output valid JSON.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.2, // Low temp for more deterministic output
        }),
      );

      if (response.statusCode == 200) {
        print('--- DEEPSEEK AI RESPONSE ---');
        print(response.body);
        print('----------------------------');
        
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString().trim();
        
        // Clean up markdown if AI returned it despite instructions
        String jsonStr = content;
        if (jsonStr.startsWith('```json')) {
          jsonStr = jsonStr.substring(7);
        } else if (jsonStr.startsWith('```')) {
          jsonStr = jsonStr.substring(3);
        }
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3);
        }
        
        final parsedJson = jsonDecode(jsonStr.trim()) as Map<String, dynamic>;
        
        Map<String, double> result = {};
        parsedJson.forEach((key, value) {
          result[key] = (value as num).toDouble();
        });
        
        return result;
      } else {
        throw Exception('DeepSeek API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DeepSeek Error: $e');
      throw Exception('Failed to generate budget plan');
    }
  }

  Future<String?> categorizeExpense(String description, List<String> categories) async {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final prompt = '''
Categorize the following expense description into EXACTLY ONE of the provided categories. 
Return ONLY the exact category name and nothing else. Do not add punctuation.
Categories: ${categories.join(', ')}
Description: "$description"
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1, // very low temperature for strict classification
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString().trim();
        
        // Validate if returned string matches a category
        if (categories.contains(content)) {
          return content;
        }
        
        // Fallback fuzzy match
        for (final cat in categories) {
          if (content.toLowerCase().contains(cat.toLowerCase())) {
            return cat;
          }
        }
      }
      return null;
    } catch (e) {
      print('Categorization error: $e');
      return null;
    }
  }

  Future<String> chatWithSavingsCoach(List<Map<String, String>> conversationHistory) async {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('DeepSeek API key not found in .env');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': conversationHistory,
          'temperature': 0.7, // higher temperature for conversational chat
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to AI Coach: $e');
    }
  }
}
