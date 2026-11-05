import 'package:shared_preferences/shared_preferences.dart';

abstract final class OnboardingStorage {
  static const String key = 'onboarding_vu';

  static Future<bool> alreadySeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
