import '../../domain/entities/prospect.dart';
import '../../domain/ports/prospect_enrichment_port.dart';

class NoopEnrichmentAdapter implements ProspectEnrichmentPort {
  @override
  Future<EnrichmentResult> enrich(Prospect prospect) async {
    return EnrichmentResult(prospect: prospect);
  }
}

class SireneEnrichmentAdapter implements ProspectEnrichmentPort {
  @override
  Future<EnrichmentResult> enrich(Prospect prospect) async {
    // Stub MVP — intégration API INSEE SIRENE en v2.
    return EnrichmentResult(
      prospect: prospect,
      sources: const ['sirene_stub'],
    );
  }
}

class GooglePlacesEnrichmentAdapter implements ProspectEnrichmentPort {
  @override
  Future<EnrichmentResult> enrich(Prospect prospect) async {
    // Stub MVP — intégration Google Places API en v2.
    return EnrichmentResult(
      prospect: prospect,
      sources: const ['google_places_stub'],
    );
  }
}
