import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/auth/domain/auth_platform.dart';

void main() {
  test('isMobileBiometricPlatform aligné sur defaultTargetPlatform', () {
    final expected = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    expect(isMobileBiometricPlatform, expected);
  });
}
