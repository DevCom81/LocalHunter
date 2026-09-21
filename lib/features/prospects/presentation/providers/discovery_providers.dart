import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../campaigns/domain/entities/discovery_source.dart';
import '../../data/discovery/combined_discovery_provider.dart';
import '../../data/discovery/google_places_discovery_provider.dart';
import '../../data/discovery/sirene_discovery_provider.dart';
import '../../data/services/places_search_service.dart';
import '../../data/services/sirene_search_service.dart';
import '../../domain/discovery/discovery_provider.dart';

final placesSearchServiceProvider = Provider<PlacesSearchService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PlacesSearchService(client);
});

final sireneSearchServiceProvider = Provider<SireneSearchService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SireneSearchService(client);
});

/// Résout le [DiscoveryProvider] selon la source campagne (Phase 9–12).
DiscoveryProvider? discoveryForSource(Ref ref, DiscoverySource source) {
  final placesSvc = ref.read(placesSearchServiceProvider);
  final sireneSvc = ref.read(sireneSearchServiceProvider);

  switch (source) {
    case DiscoverySource.sirene:
      if (sireneSvc == null) return null;
      return SireneDiscoveryProvider(sireneSvc);
    case DiscoverySource.places:
      if (placesSvc == null) return null;
      return GooglePlacesDiscoveryProvider(placesSvc);
    case DiscoverySource.combined:
      if (placesSvc == null && sireneSvc == null) return null;
      if (placesSvc == null) return SireneDiscoveryProvider(sireneSvc!);
      if (sireneSvc == null) return GooglePlacesDiscoveryProvider(placesSvc);
      return CombinedDiscoveryProvider(
        places: GooglePlacesDiscoveryProvider(placesSvc),
        sirene: SireneDiscoveryProvider(sireneSvc),
      );
  }
}

/// Défaut combined (Phase 12). Préférer [discoveryForSource] à la recherche.
final campaignDiscoveryProvider = Provider<DiscoveryProvider?>((ref) {
  return discoveryForSource(ref, DiscoverySource.combined);
});
