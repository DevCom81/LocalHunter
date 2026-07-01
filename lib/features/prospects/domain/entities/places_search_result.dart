import '../../domain/entities/prospect.dart';

class PlacesSearchResult {
  const PlacesSearchResult({
    required this.prospects,
    required this.fromCache,
    required this.count,
  });

  final List<Prospect> prospects;
  final bool fromCache;
  final int count;
}
