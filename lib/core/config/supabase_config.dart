import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class SupabaseConfig {
  static const _urlFromDefine = String.fromEnvironment('SUPABASE_URL');
  static const _keyFromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const _defaultUrl = 'https://your-project.supabase.co';
  static const _defaultKey = 'your-anon-key';

  static String get url {
    if (_urlFromDefine.isNotEmpty) return _urlFromDefine;
    return _fromDotenv('SUPABASE_URL', _defaultUrl);
  }

  static String get publishableKey {
    if (_keyFromDefine.isNotEmpty) return _keyFromDefine;
    return _fromDotenv('SUPABASE_ANON_KEY', _defaultKey);
  }

  static String _fromDotenv(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    return dotenv.env[key]?.trim() ?? fallback;
  }

  static bool get isConfigured =>
      !url.contains('your-project') &&
      !publishableKey.contains('your-anon');
}
