import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../scoring/data/services/prospect_scoring_service.dart';
import '../../../scoring/domain/entities/scoring_grid.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../data/services/bodacc_enrichment_service.dart';
import '../../domain/entities/prospect.dart';
import '../../domain/entities/prospect_with_score.dart';
import '../../domain/repositories/prospect_repository.dart';
import '../../domain/services/bodacc_selection.dart';
import 'prospect_providers.dart';

final bodaccEnrichmentServiceProvider =
    Provider<BodaccEnrichmentService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return BodaccEnrichmentService(client);
});

const bodaccSelection = BodaccSelection();

Future<int> _executeBodaccEnrichment({
  required BodaccEnrichmentService? service,
  required ProspectRepository repo,
  required ScoringGrid grid,
  required List<Prospect> targets,
  required bool forceRefresh,
  required void Function(String campaignId) invalidateCampaign,
  required void Function(String prospectId) invalidateProspect,
  required String campaignId,
}) async {
  if (service == null || targets.isEmpty) return 0;

  final enrichedIds = await service.enrich(
    prospects: targets,
    forceRefresh: forceRefresh,
  );
  if (enrichedIds.isEmpty) return 0;

  try {
    final scoring = ProspectScoringService(grid: grid);
    final refreshed = <Prospect>[];
    for (final id in enrichedIds) {
      final p = await repo.getById(id);
      if (p == null) continue;
      final applied = scoring.applyExclusion(p);
      if (applied.isExcluded && !p.isExcluded) {
        await repo.updateExclusion(
          applied.id,
          isExcluded: true,
          exclusionReason: applied.exclusionReason,
          status: applied.status,
        );
      }
      refreshed.add(applied);
    }
    if (refreshed.isNotEmpty) {
      await repo.saveScores(refreshed.map(scoring.computeScore).toList());
    }
  } catch (_) {
    // Signaux déjà persistés par l'Edge.
  }

  invalidateCampaign(campaignId);
  for (final id in enrichedIds) {
    invalidateProspect(id);
  }
  return enrichedIds.length;
}

/// Enrichissement BODACC (UI). Best-effort.
Future<int> runBodaccEnrichment(
  WidgetRef ref, {
  required String campaignId,
  List<Prospect>? only,
  bool forceRefresh = false,
}) async {
  final service = ref.read(bodaccEnrichmentServiceProvider);
  final repo = ref.read(prospectRepositoryProvider);
  final grid =
      await ref.read(campaignScoringGridProvider(campaignId).future);

  final List<Prospect> targets;
  if (only != null) {
    targets = only
        .where(
          (p) => bodaccSelection.isEligible(p, ignoreCache: forceRefresh),
        )
        .take(BodaccEnrichmentService.maxProspects)
        .toList();
  } else {
    final items =
        await ref.read(prospectsWithScoresProvider(campaignId).future);
    targets = bodaccSelection
        .selectTop(items, ignoreCache: forceRefresh)
        .map((i) => i.prospect)
        .toList();
  }

  return _executeBodaccEnrichment(
    service: service,
    repo: repo,
    grid: grid,
    targets: targets,
    forceRefresh: forceRefresh,
    campaignId: campaignId,
    invalidateCampaign: (id) =>
        ref.invalidate(prospectsWithScoresProvider(id)),
    invalidateProspect: (id) => ref.invalidate(prospectByIdProvider(id)),
  );
}

/// Depuis un [Ref] (PlacesSearchNotifier) avec scores déjà connus.
Future<int> runBodaccEnrichmentFromRef(
  Ref ref, {
  required String campaignId,
  List<ProspectWithScore>? items,
  bool forceRefresh = false,
}) async {
  final service = ref.read(bodaccEnrichmentServiceProvider);
  final repo = ref.read(prospectRepositoryProvider);
  final grid =
      await ref.read(campaignScoringGridProvider(campaignId).future);

  final List<Prospect> targets;
  if (items != null) {
    targets = bodaccSelection
        .selectTop(items, ignoreCache: forceRefresh)
        .map((i) => i.prospect)
        .toList();
  } else {
    final loaded =
        await ref.read(prospectsWithScoresProvider(campaignId).future);
    targets = bodaccSelection
        .selectTop(loaded, ignoreCache: forceRefresh)
        .map((i) => i.prospect)
        .toList();
  }

  return _executeBodaccEnrichment(
    service: service,
    repo: repo,
    grid: grid,
    targets: targets,
    forceRefresh: forceRefresh,
    campaignId: campaignId,
    invalidateCampaign: (id) =>
        ref.invalidate(prospectsWithScoresProvider(id)),
    invalidateProspect: (id) => ref.invalidate(prospectByIdProvider(id)),
  );
}
