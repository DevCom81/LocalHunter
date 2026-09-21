import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_platform.dart';

class BiometricCredentials {
  const BiometricCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

/// Coffre email+mdp pour déverrouillage biométrique (Phase 2).
/// Indépendant de « Se souvenir de moi ». Non effacé au logout.
class BiometricCredentialStore {
  BiometricCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();


  static const _keyEmail = 'bio_auth_email';
  static const _keyPassword = 'bio_auth_password';
  static const _keyEnabled = 'bio_auth_enabled';

  final FlutterSecureStorage _storage;

  Future<bool> isEnabled() async {
    if (!isMobileBiometricPlatform) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> save({
    required String email,
    required String password,
  }) async {
    if (!isMobileBiometricPlatform) return;
    final trimmed = email.trim();
    await _storage.write(key: _keyEmail, value: trimmed);
    await _storage.write(key: _keyPassword, value: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);
  }

  Future<BiometricCredentials?> read() async {
    if (!isMobileBiometricPlatform) return null;
    if (!await isEnabled()) return null;
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return BiometricCredentials(email: email, password: password);
  }

  /// Désactivation explicite (pas appelé au logout — arbitrage 4).
  Future<void> clear() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
  }
}
