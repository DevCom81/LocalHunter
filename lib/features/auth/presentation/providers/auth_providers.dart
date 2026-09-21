import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/remember_me_store.dart';

const _supabaseNotConfiguredMessage =
    'Supabase non configuré. Copiez .env.example vers .env à la racine du '
    'projet (puis relancez l\'app), ou utilisez --dart-define=SUPABASE_URL '
    'et --dart-define=SUPABASE_ANON_KEY.';

class AuthFormState {
  const AuthFormState({
    this.email = '',
    this.password = '',
    this.fullName = '',
    this.isLoading = false,
    this.error,
    this.info,
  });

  final String email;
  final String password;
  final String fullName;
  final bool isLoading;
  final String? error;
  final String? info;

  AuthFormState copyWith({
    String? email,
    String? password,
    String? fullName,
    bool? isLoading,
    Object? error = _unset,
    Object? info = _unset,
  }) {
    return AuthFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      info: identical(info, _unset) ? this.info : info as String?,
    );
  }
}

const _unset = Object();

String _formatAuthError(Object error) {
  if (error is AuthException) {
    return error.message;
  }
  return error.toString();
}

class AuthController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void setEmail(String value) => state = state.copyWith(email: value);

  void setPassword(String value) => state = state.copyWith(password: value);

  void setFullName(String value) => state = state.copyWith(fullName: value);

  Future<bool> signIn({
    bool rememberMe = true,
    bool updateRememberMePrefs = true,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(error: _supabaseNotConfiguredMessage);
      return false;
    }
    state = state.copyWith(isLoading: true, error: null, info: null);
    try {
      final client = ref.read(supabaseClientProvider);
      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Client Supabase indisponible. Vérifiez la configuration et redémarrez l\'app.',
        );
        return false;
      }
      await client.auth.signInWithPassword(
        email: state.email.trim(),
        password: state.password,
      );
      if (updateRememberMePrefs) {
        await RememberMeStore.save(
          rememberMe: rememberMe,
          email: state.email.trim(),
        );
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _formatAuthError(e));
      return false;
    }
  }

  /// Connexion via credentials déjà déverrouillés (biométrie).
  /// N'altère pas les prefs « Se souvenir de moi ».
  Future<bool> signInWithStoredCredentials({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(email: email, password: password);
    return signIn(updateRememberMePrefs: false);
  }

  Future<bool> signUp() async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(error: _supabaseNotConfiguredMessage);
      return false;
    }
    state = state.copyWith(isLoading: true, error: null, info: null);
    try {
      final client = ref.read(supabaseClientProvider);
      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Client Supabase indisponible. Vérifiez la configuration et redémarrez l\'app.',
        );
        return false;
      }
      await client.auth.signUp(
        email: state.email.trim(),
        password: state.password,
        data: {'full_name': state.fullName.trim()},
      );
      state = state.copyWith(
        isLoading: false,
        info:
            'Compte créé. Consultez votre boîte mail pour activer votre compte.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _formatAuthError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    final client = ref.read(supabaseClientProvider);
    await client?.auth.signOut();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthFormState>(AuthController.new);

final isAuthenticatedProvider = Provider<bool>((ref) {
  if (!SupabaseConfig.isConfigured) return true;
  return ref.watch(currentUserProvider) != null;
});
