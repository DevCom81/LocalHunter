import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return Stream.value(AuthState(AuthChangeEvent.initialSession, null));
  }
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  // Se réévalue à chaque événement d'auth (connexion, déconnexion,
  // changement de compte) : les providers de données qui en dépendent
  // sont ainsi invalidés et rechargés pour le nouvel utilisateur.
  ref.watch(authStateProvider);
  return client.auth.currentUser;
});
