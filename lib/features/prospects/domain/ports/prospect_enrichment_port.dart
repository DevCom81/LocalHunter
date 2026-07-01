import '../entities/prospect.dart';

class EnrichmentResult {
  const EnrichmentResult({
    required this.prospect,
    this.sources = const [],
  });

  final Prospect prospect;
  final List<String> sources;
}

abstract class ProspectEnrichmentPort {
  Future<EnrichmentResult> enrich(Prospect prospect);
}
