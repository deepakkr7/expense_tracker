import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Public endpoint configuration only. Never put provider secrets in the app.
class BackendService {
  static const endpoint = String.fromEnvironment('SPENDWISE_API_URL');

  Future<Map<String, dynamic>> call(
    String action,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.tryParse(endpoint);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw Exception(
        'This feature is not configured yet. Please contact support.',
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in again.');
    final token = await user.getIdToken();
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'action': action, ...data}),
        )
        .timeout(const Duration(seconds: 90));
    if (response.statusCode != 200) {
      final message = switch (response.statusCode) {
        401 => 'Please sign in again.',
        403 =>
          'Verify your email and sign in again. If you requested deletion, contact support.',
        409 =>
          'For your security, sign out and sign in again before deleting your account.',
        429 => 'Too many requests. Please try again later.',
        _ => 'The service is unavailable. Please try again later.',
      };
      throw Exception(message);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
