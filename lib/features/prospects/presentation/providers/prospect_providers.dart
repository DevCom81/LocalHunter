import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/priority_level.dart';
import '../../../../core/constants/prospect_status.dart';
import '../../../../core/network/demo_providers.dart';
import '../../domain/entities/prospect.dart';
import '../../domain/entities/prospect_with_score.dart';
import '../../../../core/network/repository_providers.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../../scoring/data/services/prospect_scoring_service.dart';
import '../../../subscription/domain/entities/subscription_tier.dart';
import '../../../subscription/presentation/providers/prospect_quota_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../data/services/csv_importer.dart';

class CsvImportResult {
  const CsvImportResult({required this.imported, required this.truncatedByQuota});

  final int imported;

  /// Import tronqué par le quota freemium (5 prospects par campagne).
  final bool truncatedByQuota;
}

class ImportCsvNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CsvImportResult> importFromContent({
    required String campaignId,
    required String content,
  }) async {
    state = const AsyncLoading();
    try {
      final campaign =
          await ref.read(campaignRepositoryProvider).getById(campaignId);
      if (campaign == null) throw Exception('Campagne introuvable');

      final tier = await ref.read(subscriptionTierProvider.future);
      final maxProspects = tier.limits.maxProspectsPerCampaign;
      final remaining = await ref
          .read(remainingProspectSlotsProvider(campaignId).future);
      if (remaining != null && remaining <= 0) {
        throw Exception(
          'Quota prospects atteint '
          '(${maxProspects ?? '?'} par campagne). '
          '${PlanLimits.upgradeMessage}',
        );
      }

      final parsed = const CsvImporter().parse(content, campaignId: campaignId);
      final truncated = remaining != null && parsed.length > remaining;
      final kept = truncated ? parsed.take(remaining).toList() : parsed;

      final grid = await ref.read(campaignScoringGridProvider(campaignId).future);
      final scoring = ProspectScoringService(grid: grid);
      final processed = kept.map(scoring.applyExclusion).toList();
      await ref.read(prospectRepositoryProvider).importProspects(
            campaignId,
            processed,
          );
      final scores = processed.map(scoring.computeScore).toList();
      await ref.read(prospectRepositoryProvider).saveScores(scores);

      ref.invalidate(prospectsWithScoresProvider(campaignId));
      ref.invalidate(remainingProspectSlotsProvider(campaignId));
      state = const AsyncData(null);
      return CsvImportResult(
        imported: processed.length,
        truncatedByQuota: truncated,
      );
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
      await ref.watch(campaignRepositoryProvider).getById(campaignId);
  if (campaign == null) return [];

  final prospectRepo = ref.watch(prospectRepositoryProvider);
  final prospects = await prospectRepo.getByCampaign(campaignId);
  final cached = await prospectRepo.getScoresByCampaign(campaignId);
  final grid = await ref.read(campaignScoringGridProvider(campaignId).future);
  final scoring = ProspectScoringService(grid: grid);

  return prospects.map((prospect) {
    final score = cached[prospect.id] ?? scoring.computeScore(prospect);
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
    if (filters.excludeFranchises && p.isExcluded) return false;
    if (filters.emailAvailable && !p.hasEmail) return false;
    if (filters.phoneAvailable && !p.hasPhone) return false;
    return true;
  }).toList();
});

/// Chargement direct : prospect par id, puis scores de sa seule campagne
/// (parcourir toutes les campagnes rendait l'écran détail dépendant du
/// chargement de chacune d'elles).
final prospectByIdProvider =
    FutureProvider.family<ProspectWithScore?, String>((ref, prospectId) async {
  final prospect =
      await ref.watch(prospectRepositoryProvider).getById(prospectId);
  if (prospect == null) return null;
  final items = await ref.watch(
    prospectsWithScoresProvider(prospect.campaignId).future,
  );
  return items.where((i) => i.prospect.id == prospectId).firstOrNull;
});

/// Marque un prospect « contacté » (ou le repasse en « nouveau »),
/// puis rafraîchit la liste CRM de sa campagne.
Future<void> setProspectContacted(
  WidgetRef ref,
  Prospect prospect, {
  required bool contacted,
}) async {
  final status =
      contacted ? ProspectStatus.contacted : ProspectStatus.newProspect;
  await setProspectStatus(ref, prospect, status);
}

/// Met à jour le statut CRM d'un prospect et invalide les providers liés.
Future<void> setProspectStatus(
  WidgetRef ref,
  Prospect prospect,
  ProspectStatus status,
) async {
  await ref.read(prospectRepositoryProvider).updateStatus(prospect.id, status);
  ref.invalidate(prospectsWithScoresProvider(prospect.campaignId));
  ref.invalidate(prospectByIdProvider(prospect.id));
}
