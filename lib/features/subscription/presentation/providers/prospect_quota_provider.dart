import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../domain/entities/subscription_tier.dart';
import 'subscription_providers.dart';

/// Places restantes pour une campagne. `null` = illimité (Pro Plan).
/// Reflet du trigger SQL `prospects_tier_limit` : l'UI tronque en amont
/// pour une expérience propre, la base reste le garde-fou final.
final remainingProspectSlotsProvider =
    FutureProvider.family<int?, String>((ref, campaignId) async {
  final tier = await ref.watch(subscriptionTierProvider.future);
  final max = tier.limits.maxProspectsPerCampaign;
  if (max == null) return null;
  final existing =
      await ref.read(prospectRepositoryProvider).getByCampaign(campaignId);
  final remaining = max - existing.length;
  return remaining < 0 ? 0 : remaining;
});
