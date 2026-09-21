import 'package:flutter/foundation.dart';

/// Biométrie auth : Android / iOS uniquement (pas web ni desktop).
bool get isMobileBiometricPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
