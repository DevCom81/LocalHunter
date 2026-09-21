import '../../domain/discovery/business_candidate_resolver.dart';
import '../../domain/discovery/discovery_provider.dart';

/// Exécute Places + SIRENE en parallèle puis rapproche (Phase 12).
class CombinedDiscoveryProvider implements DiscoveryProvider {
  CombinedDiscoveryProvider({
    required DiscoveryProvider places,
    required DiscoveryProvider sirene,
    BusinessCandidateResolver resolver = const BusinessCandidateResolver(),
  })  : _places = places,
        _sirene = sirene,
        _resolver = resolver;

  final DiscoveryProvider _places;
  final DiscoveryProvider _sirene;
  final BusinessCandidateResolver _resolver;

  @override
  String get id => 'combined';

  @override
  Future<DiscoveryResult> discover(DiscoveryQuery query) async {
    final results = await Future.wait([
      _safeDiscover(_places, query),
      _safeDiscover(_sirene, query),
    ]);
    final placesResult = results[0];
    final sireneResult = results[1];

    final merged = _resolver.resolve(
      places: placesResult.prospects,
      sirene: sireneResult.prospects,
    );

    // Cap au maxResults après fusion (évite explosion).
    final capped = merged.length > query.maxResults
        ? merged.take(query.maxResults).toList()
        : merged;

    return DiscoveryResult(
      providerId: id,
      prospects: capped,
      fromCache: placesResult.fromCache && sireneResult.fromCache,
      count: capped.length,
    );
  }

  Future<DiscoveryResult> _safeDiscover(
    DiscoveryProvider provider,
    DiscoveryQuery query,
  ) async {
    try {
      return await provider.discover(query);
    } catch (_) {
      return DiscoveryResult(
        providerId: provider.id,
        prospects: const [],
        fromCache: false,
        count: 0,
      );
    }
  }
}
