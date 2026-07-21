import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../../scoring/data/services/prospect_scoring_service.dart';
import '../../../subscription/domain/entities/subscription_tier.dart';
import '../../../subscription/presentation/providers/prospect_quota_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../data/services/places_search_service.dart';
import '../../data/services/prospect_enrichment_service.dart';
import '../../domain/entities/places_search_result.dart';
import '../../domain/entities/prospect.dart';
import 'prospect_providers.dart';

final placesSearchServiceProvider = Provider<PlacesSearchService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PlacesSearchService(client);
});

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
      final service = ref.read(placesSearchServiceProvider);
      if (service == null) {
        throw Exception('Recherche Places disponible uniquement avec Supabase');
      }

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

      final result = await service.search(
        campaignId: campaignId,
        city: campaign.city,
        sector: campaign.sector,
        radiusKm: campaign.radiusKm,
        maxResults: campaign.targetCount,
      );

      final truncated =
          remaining != null && result.prospects.length > remaining;
      final kept = truncated
          ? result.prospects.take(remaining).toList()
          : result.prospects;

      // Enrichissement SIRENE + PageSpeed avant scoring : les données
      // (ancienneté, site lent, établissement fermé) alimentent la grille.
      final enrichedList = await _enrich(kept, campaign.city);

      final grid = await ref.read(campaignScoringGridProvider(campaignId).future);
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
      return outcome;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Best-effort : si l'Edge Function échoue, les prospects sont
  /// importés sans enrichissement.
  Future<List<Prospect>> _enrich(List<Prospect> prospects, String city) async {
    final service = ref.read(prospectEnrichmentServiceProvider);
    if (service == null) return prospects;
    final byId = await service.enrich(city: city, prospects: prospects);
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
