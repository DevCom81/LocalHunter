import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale « Se souvenir de moi » (Phase 1).
/// - email mémorisé si rememberMe == true
/// - si rememberMe == false : session non restaurée au prochain cold start
class RememberMeStore {
  RememberMeStore._();

  static const _keyRemember = 'auth_remember_me';
  static const _keyEmail = 'auth_remembered_email';

  /// Défaut : true (comportement historique = session persistée).
  static Future<bool> loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRemember) ?? true;
  }

  static Future<String?> loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? true;
    if (!remember) return null;
    final email = prefs.getString(_keyEmail)?.trim();
    if (email == null || email.isEmpty) return null;
    return email;
  }

  static Future<void> save({
    required bool rememberMe,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemember, rememberMe);
    if (rememberMe) {
      final trimmed = email?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        await prefs.setString(_keyEmail, trimmed);
      }
    } else {
      await prefs.remove(_keyEmail);
    }
  }
}
