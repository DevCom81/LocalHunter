import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../../scoring/data/grids/default_scoring_grids.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';

class CampaignsNotifier extends AsyncNotifier<List<Campaign>> {
  @override
  Future<List<Campaign>> build() async {
    return ref.read(campaignRepositoryProvider).getAll();
  }

  Future<Campaign> create(CreateCampaignInput input) async {
    final userId = ref.read(currentUserProvider)?.id ?? DemoData.userId;
    final gridRepo = ref.read(scoringGridRepositoryProvider);
    final gridId = await _resolveCampaignGridId(
      gridRepo: gridRepo,
      input: input,
      userId: userId,
    );

    final created = await ref.read(campaignRepositoryProvider).create(
          CreateCampaignInput(
            name: input.name,
            sector: input.sector,
            city: input.city,
            radiusKm: input.radiusKm,
            targetCount: input.targetCount,
            offerType: input.offerType,
            scoringGridId: gridId,
          ),
        );
    ref.invalidate(scoringGridsProvider);
    state = AsyncData([created, ...?state.value]);
    return created;
  }

  Future<String> _resolveCampaignGridId({
    required dynamic gridRepo,
    required CreateCampaignInput input,
    required String userId,
  }) async {
    final gridName = '${input.name} — scoring';
    if (input.scoringGridId != null) {
      final source = await gridRepo.getById(input.scoringGridId!);
      if (source != null) {
        final cloned = DefaultScoringGrids.duplicateFrom(
          source,
          userId: userId,
          name: gridName,
        );
        final saved = await gridRepo.save(cloned);
        return saved.id;
      }
    }
    final blank = DefaultScoringGrids.blank(userId: userId, name: gridName);
    final saved = await gridRepo.save(blank);
    return saved.id;
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
  return ref.read(campaignRepositoryProvider).getById(id);
});
