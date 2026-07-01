import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/priority_level.dart';
import '../../../../core/network/demo_providers.dart';
import '../../domain/entities/prospect_with_score.dart';
import '../../../../core/network/repository_providers.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../../scoring/data/services/prospect_scoring_service.dart';
import '../../data/services/csv_importer.dart';

class ImportCsvNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> importFromContent({
    required String campaignId,
    required String content,
  }) async {
    state = const AsyncLoading();
    try {
      final campaign =
          await ref.read(campaignRepositoryProvider).getById(campaignId);
      if (campaign == null) throw Exception('Campagne introuvable');

      final parsed = const CsvImporter().parse(content, campaignId: campaignId);
      final grid = await ref.read(campaignScoringGridProvider(campaignId).future);
      final scoring = ProspectScoringService(grid: grid);
      final processed = parsed.map(scoring.applyExclusion).toList();
      await ref.read(prospectRepositoryProvider).importProspects(
            campaignId,
            processed,
          );
      final scores = processed
          .map((p) => scoring.computeScore(p, campaign.offerType))
          .toList();
      await ref.read(prospectRepositoryProvider).saveScores(scores);

      ref.invalidate(prospectsWithScoresProvider(campaignId));
      state = const AsyncData(null);
      return processed.length;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final importCsvProvider = AsyncNotifierProvider<ImportCsvNotifier, void>(
  ImportCsvNotifier.new,
);

final prospectsWithScoresProvider =
    FutureProvider.family<List<ProspectWithScore>, String>((ref, campaignId) async {
  final campaign =
      await ref.read(campaignRepositoryProvider).getById(campaignId);
  if (campaign == null) return [];

  final prospects =
      await ref.read(prospectRepositoryProvider).getByCampaign(campaignId);
  final cached =
      await ref.read(prospectRepositoryProvider).getScoresByCampaign(campaignId);
  final grid = await ref.read(campaignScoringGridProvider(campaignId).future);
  final scoring = ProspectScoringService(grid: grid);

  return prospects.map((prospect) {
    final score = cached[prospect.id] ??
        scoring.computeScore(prospect, campaign.offerType);
    return ProspectWithScore(prospect: prospect, score: score);
  }).toList();
});

final filteredProspectsProvider =
    FutureProvider.family<List<ProspectWithScore>, String>((ref, campaignId) async {
  final all = await ref.watch(prospectsWithScoresProvider(campaignId).future);
  final filters = ref.watch(prospectFiltersProvider);

  return all.where((item) {
    final p = item.prospect;
    final s = item.score;
    if (filters.highPriorityOnly && s.priority != PriorityLevel.high) {
      return false;
    }
    if (s.globalScore < filters.minScore) return false;
    if (s.siteScore < filters.minSiteStars) return false;
    if (s.softwareScore < filters.minSoftwareStars) return false;
    if (filters.excludeFranchises && p.isExcluded) return false;
    if (filters.noWebsiteOnly && p.hasWebsite) return false;
    if (filters.weakWebsiteOnly && s.siteScore < 3) return false;
    if (filters.emailAvailable && !p.hasEmail) return false;
    if (filters.phoneAvailable && !p.hasPhone) return false;
    return true;
  }).toList();
});

final prospectByIdProvider =
    FutureProvider.family<ProspectWithScore?, String>((ref, prospectId) async {
  final campaigns = await ref.watch(campaignsProvider.future);
  for (final campaign in campaigns) {
    final items = await ref.watch(
      prospectsWithScoresProvider(campaign.id).future,
    );
    for (final item in items) {
      if (item.prospect.id == prospectId) return item;
    }
  }
  return null;
});
