import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../data/repositories/supabase_subscription_repository.dart';
import '../../domain/entities/subscription_tier.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (useSupabase(ref)) {
    return SupabaseSubscriptionRepository(ref.watch(supabaseClientProvider)!);
  }
  return DemoSubscriptionRepository();
});

final subscriptionTierProvider = FutureProvider<SubscriptionTier>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id ?? DemoData.userId;
  return ref.read(subscriptionRepositoryProvider).getTier(userId);
});

/// Tier courant avec repli freemium tant que le profil n'est pas chargé
/// (l'UI ne doit jamais sur-promettre en cas de doute).
SubscriptionTier tierOrFreemium(AsyncValue<SubscriptionTier> async) {
  return async.valueOrNull ?? SubscriptionTier.freemium;
}

/// Résout le tier en **attendant** le chargement du profil : à utiliser dans
/// les gardes de quota (un `ref.read` synchrone pendant le chargement ferait
/// passer un compte premium pour freemium). Repli freemium en cas d'erreur.
Future<SubscriptionTier> resolveTier(WidgetRef ref) async {
  try {
    return await ref.read(subscriptionTierProvider.future);
  } catch (_) {
    return SubscriptionTier.freemium;
  }
}
