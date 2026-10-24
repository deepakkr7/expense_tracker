import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPreferences {
  static String get _aiKey =>
      'ai_consent_v1_${FirebaseAuth.instance.currentUser?.uid}';
  static Future<bool> aiEnabled() async {
    final key = _aiKey;
    return (await SharedPreferences.getInstance()).getBool(key) ?? false;
  }
  static Future<void> setAiEnabled(bool enabled) async {
    final key = _aiKey;
    await (await SharedPreferences.getInstance()).setBool(key, enabled);
  }

  static Future<void> clear() async {
    final key = _aiKey;
    await (await SharedPreferences.getInstance()).remove(key);
  }
}
