import '../../domain/discovery/discovery_provider.dart';
import '../services/places_search_service.dart';

/// Adapter Discovery → Edge `search-places` (comportement inchangé).
///
/// Conserve [PlacesSearchService] comme client HTTP ; ce wrapper expose
/// uniquement le port [DiscoveryProvider] pour l'orchestration campagne.
class GooglePlacesDiscoveryProvider implements DiscoveryProvider {
  GooglePlacesDiscoveryProvider(this._places);

  final PlacesSearchService _places;

  @override
  String get id => 'google_places';

  @override
  Future<DiscoveryResult> discover(DiscoveryQuery query) async {
    final raw = await _places.search(
      campaignId: query.campaignId,
      city: query.city,
      sector: query.sector,
      radiusKm: query.radiusKm,
      maxResults: query.maxResults,
    );
    return DiscoveryResult(
      providerId: id,
      prospects: raw.prospects,
      fromCache: raw.fromCache,
      count: raw.count,
    );
  }
}
