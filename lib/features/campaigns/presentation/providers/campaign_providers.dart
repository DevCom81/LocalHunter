import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../../../../core/network/repository_providers.dart';

class CampaignsNotifier extends AsyncNotifier<List<Campaign>> {
  @override
  Future<List<Campaign>> build() async {
    // watch (et non read) : le repository change avec l'utilisateur
    // connecté, la liste doit être rechargée au changement de compte.
    return ref.watch(campaignRepositoryProvider).getAll();
  }

  /// La campagne référence directement une grille personnelle (aucune copie
  /// n'est créée : une grille peut être partagée par plusieurs campagnes).
  Future<Campaign> create(CreateCampaignInput input) async {
    final gridRepo = ref.read(scoringGridRepositoryProvider);
    final gridId = input.scoringGridId != null &&
            await gridRepo.getById(input.scoringGridId!) != null
        ? input.scoringGridId
        : null;

    final created = await ref.read(campaignRepositoryProvider).create(
          CreateCampaignInput(
            name: input.name,
            sector: input.sector,
            city: input.city,
            radiusKm: input.radiusKm,
            targetCount: input.targetCount,
            scoringGridId: gridId,
            targetProfile: input.targetProfile,
            discoverySource: input.discoverySource,
          ),
        );
    state = AsyncData([created, ...?state.value]);
    return created;
  }

  Future<void> delete(String id) async {
    await ref.read(campaignRepositoryProvider).delete(id);
    ref.invalidate(campaignByIdProvider(id));
    state = AsyncData(
      [...?state.value]..removeWhere((c) => c.id == id),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(campaignRepositoryProvider).getAll());
  }
}

final campaignsProvider =
    AsyncNotifierProvider<CampaignsNotifier, List<Campaign>>(
  CampaignsNotifier.new,
);

final campaignByIdProvider =
    FutureProvider.family<Campaign?, String>((ref, id) async {
  return ref.watch(campaignRepositoryProvider).getById(id);
});
