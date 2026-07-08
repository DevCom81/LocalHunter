import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/subscription_tier.dart';
import '../../domain/repositories/subscription_repository.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  SupabaseSubscriptionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SubscriptionTier> getTier(String userId) async {
    final row = await _client
        .from('profiles')
        .select('subscription_tier')
        .eq('id', userId)
        .maybeSingle();
    return SubscriptionTier.fromDb(row?['subscription_tier'] as String?);
  }
}

/// Mode démo (sans Supabase) : accès complet, ce n'est pas un vrai compte.
class DemoSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<SubscriptionTier> getTier(String userId) async =>
      SubscriptionTier.premium;
}
