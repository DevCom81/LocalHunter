import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:localhunter/features/auth/data/remember_me_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RememberMeStore', () {
    test('défaut rememberMe = true', () async {
      expect(await RememberMeStore.loadRememberMe(), isTrue);
    });

    test('sauve email si rememberMe true', () async {
      await RememberMeStore.save(
        rememberMe: true,
        email: '  user@example.com ',
      );
      expect(await RememberMeStore.loadRememberMe(), isTrue);
      expect(await RememberMeStore.loadRememberedEmail(), 'user@example.com');
    });

    test('efface email si rememberMe false', () async {
      await RememberMeStore.save(rememberMe: true, email: 'a@b.fr');
      await RememberMeStore.save(rememberMe: false, email: 'a@b.fr');
      expect(await RememberMeStore.loadRememberMe(), isFalse);
      expect(await RememberMeStore.loadRememberedEmail(), isNull);
    });
  });
}
