import 'package:local_auth/local_auth.dart';

import '../domain/auth_platform.dart';

/// Wrapper `local_auth` — no-op hors Android/iOS.
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    if (!isMobileBiometricPlatform) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      final biometrics = await _auth.getAvailableBiometrics();
      return canCheck || biometrics.isNotEmpty || supported;
    } catch (_) {
      return false;
    }
  }

  /// Demande Face ID / empreinte (ou PIN appareil en secours).
  Future<bool> authenticate({
    String reason = 'Authentifiez-vous pour accéder à LocalHunter',
  }) async {
    if (!isMobileBiometricPlatform) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
