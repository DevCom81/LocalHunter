import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/remember_me_store.dart';

class LocalHunterApp extends ConsumerWidget {
  const LocalHunterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (e, stackTrace) {
    debugPrint('LocalHunter: échec chargement .env — $e\n$stackTrace');
  }
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      // Remember-me décoché : ne pas restaurer la session au cold start.
      final rememberMe = await RememberMeStore.loadRememberMe();
      if (!rememberMe) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e, stackTrace) {
      debugPrint('LocalHunter: échec init Supabase — $e\n$stackTrace');
    }
  } else {
    debugPrint(
      'LocalHunter: Supabase non configuré (mode démo). '
      'Définissez .env ou --dart-define.',
    );
  }
}
