import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/subscription_tier.dart';

/// Vérifie un achat Google Play auprès du backend (API Google + Supabase).
class PlayPurchaseVerifier {
  PlayPurchaseVerifier(this._client);

  final SupabaseClient _client;

  Future<SubscriptionTier> verify({
    required String purchaseToken,
    required String productId,
  }) async {
    final response = await _client.functions.invoke(
      'verify-play-purchase',
      body: {
        'purchaseToken': purchaseToken,
        'productId': productId,
      },
    );

    if (response.status != 200) {
      final err = response.data is Map ? response.data['error'] : response.data;
      throw Exception(err ?? 'Vérification achat (${response.status})');
    }

    final data = response.data as Map<String, dynamic>;
    return SubscriptionTier.fromDb(data['tier'] as String?);
  }
}
