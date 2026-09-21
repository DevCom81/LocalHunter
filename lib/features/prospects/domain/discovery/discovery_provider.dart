import '../entities/prospect.dart';

/// Requête de découverte d'entreprises (indépendante de la source).
///
/// Alimentée par la campagne (ville / secteur / rayon).
/// Providers livrés : Places, SIRENE. BODACC discovery = non livré
/// (BODACC reste enrichissement). CSV peut mapper ce contrat plus tard.
class DiscoveryQuery {
  const DiscoveryQuery({
    required this.campaignId,
    required this.city,
    required this.sector,
    required this.radiusKm,
    required this.maxResults,
  });

  final String campaignId;
  final String city;
  final String sector;
  final int radiusKm;
  final int maxResults;
}

/// Résultat brut de découverte — avant enrichissement et scoring.
class DiscoveryResult {
  const DiscoveryResult({
    required this.providerId,
    required this.prospects,
    required this.fromCache,
    required this.count,
  });

  /// Identifiant stable (`google_places`, `sirene`, …).
  final String providerId;
  final List<Prospect> prospects;
  final bool fromCache;
  final int count;
}

/// Port de découverte. Une source peut découvrir des entreprises ;
/// l'enrichissement reste un autre port (voir [ProspectEnrichmentPort]).
abstract class DiscoveryProvider {
  String get id;

  Future<DiscoveryResult> discover(DiscoveryQuery query);
}
