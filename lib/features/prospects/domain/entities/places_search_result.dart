import '../../domain/entities/prospect.dart';

class PlacesSearchResult {
  const PlacesSearchResult({
    required this.prospects,
    required this.fromCache,
    required this.count,
    this.truncatedByQuota = false,
  });

  final List<Prospect> prospects;
  final bool fromCache;
  final int count;

  /// Résultats tronqués par le quota freemium (5 prospects par campagne).
  final bool truncatedByQuota;
}
