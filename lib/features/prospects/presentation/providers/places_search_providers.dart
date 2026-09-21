import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../../scoring/data/services/prospect_scoring_service.dart';
import '../../../subscription/domain/entities/subscription_tier.dart';
import '../../../subscription/presentation/providers/prospect_quota_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../data/services/prospect_enrichment_service.dart';
import '../../domain/discovery/discovery_provider.dart' show DiscoveryQuery;
import '../../domain/enrichment/enrichment_needs.dart';
import '../../domain/entities/places_search_result.dart';
import '../../domain/entities/prospect.dart';
import '../../domain/entities/prospect_with_score.dart';
import 'bodacc_providers.dart';
import 'discovery_providers.dart';
import 'prospect_providers.dart';

export 'discovery_providers.dart';

final prospectEnrichmentServiceProvider =
    Provider<ProspectEnrichmentService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return ProspectEnrichmentService(client);
});

class PlacesSearchNotifier extends AsyncNotifier<PlacesSearchResult?> {
  @override
  Future<PlacesSearchResult?> build() async => null;

  Future<PlacesSearchResult> searchForCampaign(String campaignId) async {
    state = const AsyncLoading();
    try {
      final campaign =
          await ref.read(campaignRepositoryProvider).getById(campaignId);
      if (campaign == null) throw Exception('Campagne introuvable');

      final discovery = discoveryForSource(ref, campaign.discoverySource);
      if (discovery == null) {
        throw Exception('Recherche disponible uniquement avec Supabase');
      }

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

      final result = await discovery.discover(
        DiscoveryQuery(
          campaignId: campaignId,
          city: campaign.city,
          sector: campaign.sector,
          radiusKm: campaign.radiusKm,
          maxResults: campaign.targetCount,
        ),
      );

      final truncated =
          remaining != null && result.prospects.length > remaining;
      final kept = truncated
          ? result.prospects.take(remaining).toList()
          : result.prospects;

      final grid = await ref.read(campaignScoringGridProvider(campaignId).future);
      final needs = EnrichmentNeeds.fromGrid(grid);

      // Enrichissement piloté par la grille (Phase 3) ; défaut historique =
      // sirene+company+website+pagespeed si la grille les demande.
      final enrichedList = await _enrich(
        kept,
        campaign.city,
        needs.enrichProspectsProviders,
      );

      final scoring = ProspectScoringService(grid: grid);
      final processed = enrichedList.map(scoring.applyExclusion).toList();
      await ref.read(prospectRepositoryProvider).importProspects(
            campaignId,
            processed,
          );
      final scores = processed.map(scoring.computeScore).toList();
      await ref.read(prospectRepositoryProvider).saveScores(scores);

      ref.invalidate(prospectsWithScoresProvider(campaignId));
      ref.invalidate(remainingProspectSlotsProvider(campaignId));
      ref.invalidate(campaignsProvider);

      final outcome = PlacesSearchResult(
        prospects: processed,
        fromCache: result.fromCache,
        count: processed.length,
        truncatedByQuota: truncated,
      );
      state = AsyncData(outcome);

      // BODACC différé uniquement si la grille a des critères BODACC pondérés.
      if (needs.bodacc) {
        final withScores = [
          for (var i = 0; i < processed.length; i++)
            ProspectWithScore(prospect: processed[i], score: scores[i]),
        ];
        unawaited(_enrichBodaccDeferred(campaignId, withScores));
      }

      return outcome;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> _enrichBodaccDeferred(
    String campaignId,
    List<ProspectWithScore> items,
  ) async {
    try {
      final n = await runBodaccEnrichmentFromRef(
        ref,
        campaignId: campaignId,
        items: items,
      );
      if (n > 0) {
        debugPrint('enrich-bodacc différé: $n prospect(s)');
      }
    } catch (e) {
      debugPrint('enrich-bodacc différé: $e');
    }
  }

  /// Best-effort : si l'Edge Function échoue, les prospects sont
  /// importés sans enrichissement.
  Future<List<Prospect>> _enrich(
    List<Prospect> prospects,
    String city,
    List<String> enabledProviders,
  ) async {
    final service = ref.read(prospectEnrichmentServiceProvider);
    if (service == null) return prospects;
    if (enabledProviders.isEmpty) return prospects;
    final byId = await service.enrich(
      city: city,
      prospects: prospects,
      enabledProviders: enabledProviders,
    );
    if (byId.isEmpty) return prospects;
    return prospects
        .map((p) => byId[p.id]?.applyTo(p) ?? p)
        .toList();
  }
}

final placesSearchProvider =
    AsyncNotifierProvider<PlacesSearchNotifier, PlacesSearchResult?>(
  PlacesSearchNotifier.new,
);
