import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../domain/entities/subscription_tier.dart';
import 'subscription_providers.dart';

/// Places restantes pour une campagne. `null` = illimité (premium).
/// Reflet du trigger SQL `prospects_freemium_limit` : l'UI tronque en amont
/// pour une expérience propre, la base reste le garde-fou final.
final remainingProspectSlotsProvider =
    FutureProvider.family<int?, String>((ref, campaignId) async {
  final tier = await ref.watch(subscriptionTierProvider.future);
  if (tier.isPremium) return null;
  final existing =
      await ref.read(prospectRepositoryProvider).getByCampaign(campaignId);
  final remaining = FreemiumLimits.maxProspectsPerCampaign - existing.length;
  return remaining < 0 ? 0 : remaining;
});
