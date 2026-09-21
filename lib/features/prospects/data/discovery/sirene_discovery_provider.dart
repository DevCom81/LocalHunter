import '../../domain/discovery/discovery_provider.dart';
import '../services/sirene_search_service.dart';

/// Adapter Discovery → Edge `search-sirene`.
class SireneDiscoveryProvider implements DiscoveryProvider {
  SireneDiscoveryProvider(this._sirene);

  final SireneSearchService _sirene;

  @override
  String get id => 'sirene';

  @override
  Future<DiscoveryResult> discover(DiscoveryQuery query) async {
    final raw = await _sirene.search(
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
