import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../../prospects/presentation/providers/prospect_providers.dart';
import '../../data/grids/default_scoring_grids.dart';
import '../../data/services/prospect_scoring_service.dart';
import '../../domain/entities/scoring_grid.dart';

export '../../../../core/network/repository_providers.dart'
    show scoringGridRepositoryProvider;

final scoringGridsProvider = FutureProvider<List<ScoringGrid>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id ?? DemoData.userId;
  return ref.watch(scoringGridRepositoryProvider).getAll(userId);
});

final scoringGridByIdProvider =
    FutureProvider.family<ScoringGrid?, String>((ref, gridId) async {
  return ref.watch(scoringGridRepositoryProvider).getById(gridId);
});

final campaignScoringGridProvider =
    FutureProvider.family<ScoringGrid, String>((ref, campaignId) async {
  final campaign =
      await ref.watch(campaignByIdProvider(campaignId).future);
  final repo = ref.watch(scoringGridRepositoryProvider);
  final userId = ref.watch(currentUserProvider)?.id ?? DemoData.userId;

  if (campaign?.scoringGridId != null) {
    final grid = await repo.getById(campaign!.scoringGridId!);
    if (grid != null) return grid;
  }

  final grids = await repo.getAll(userId);
  return DefaultScoringGrids.resolveDefault(grids) ??
      DefaultScoringGrids.localHunterDefault(userId: userId);
});

final rescoreCampaignsForGridProvider =
    FutureProvider.family<void, String>((ref, gridId) async {
  final campaigns = await ref.read(campaignsProvider.future);
  final affected = campaigns.where((c) => c.scoringGridId == gridId);
  for (final campaign in affected) {
    final prospects = await ref
        .read(prospectRepositoryProvider)
        .getByCampaign(campaign.id);
    if (prospects.isEmpty) continue;
    final grid = await ref.read(campaignScoringGridProvider(campaign.id).future);
    final scoring = ProspectScoringService(grid: grid);
    final scores = prospects.map(scoring.computeScore).toList();
    await ref.read(prospectRepositoryProvider).saveScores(scores);
    ref.invalidate(prospectsWithScoresProvider(campaign.id));
  }
});
