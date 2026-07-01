import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../../scoring/data/services/prospect_scoring_service.dart';
import '../../data/services/places_search_service.dart';
import '../../domain/entities/places_search_result.dart';
import 'prospect_providers.dart';

final placesSearchServiceProvider = Provider<PlacesSearchService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PlacesSearchService(client);
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

      final result = await service.search(
        campaignId: campaignId,
        city: campaign.city,
        sector: campaign.sector,
        radiusKm: campaign.radiusKm,
        maxResults: campaign.targetCount,
      );

      final grid = await ref.read(campaignScoringGridProvider(campaignId).future);
      final scoring = ProspectScoringService(grid: grid);
      final processed =
          result.prospects.map(scoring.applyExclusion).toList();
      await ref.read(prospectRepositoryProvider).importProspects(
            campaignId,
            processed,
          );
      final scores = processed
          .map((p) => scoring.computeScore(p, campaign.offerType))
          .toList();
      await ref.read(prospectRepositoryProvider).saveScores(scores);

      ref.invalidate(prospectsWithScoresProvider(campaignId));
      ref.invalidate(campaignsProvider);

      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final placesSearchProvider =
    AsyncNotifierProvider<PlacesSearchNotifier, PlacesSearchResult?>(
  PlacesSearchNotifier.new,
);
