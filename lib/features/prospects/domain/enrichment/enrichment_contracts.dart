/// Miroir des contrats Edge `_shared/enrichment` (Phase 1–7).
///
/// Source de vérité runtime = TypeScript Edge ; ce fichier sert aux tests
/// et à la documentation côté Flutter. Aucun branchement HTTP Flutter ici.
library;

enum ProviderStatus { success, partial, skipped, failed }

enum CacheStatus { hit, miss, bypass, none }

enum SignalCategory {
  identity,
  activity,
  stability,
  digitalPresence,
  accessibility,
  risk,
}

class ProviderError {
  const ProviderError({
    required this.type,
    required this.message,
    required this.retryable,
  });

  final String type;
  final String message;
  final bool retryable;
}

class EnrichmentSignal {
  const EnrichmentSignal({
    required this.key,
    required this.category,
    required this.value,
    required this.source,
    required this.confidence,
    this.observedAt,
  });

  final String key;
  final SignalCategory category;
  final Object? value;
  final String source;
  final double confidence;
  final DateTime? observedAt;
}

class EnrichmentKnownData {
  const EnrichmentKnownData({
    this.placeId,
    this.siren,
    this.siret,
    this.websiteUrl,
    this.sireneActive,
    this.name,
    this.city,
    this.websiteReachable,
    this.sector,
    this.radiusKm,
    this.maxResults,
  });

  final String? placeId;
  final String? siren;
  final String? siret;
  final String? websiteUrl;

  /// false = SIRENE indique fermé / inactif (BODACC radiation).
  final bool? sireneActive;

  /// Nom commercial / enseigne (lookup SIRENE).
  final String? name;

  /// Ville de recherche (SIRENE / Places).
  final String? city;

  /// false → PageSpeed skip (site injoignable, C3).
  final bool? websiteReachable;

  /// Secteur Places (ex. restaurant).
  final String? sector;

  /// Rayon km (clé de cache Places).
  final double? radiusKm;

  /// Plafond résultats Places.
  final int? maxResults;
}

class EnrichmentOptions {
  const EnrichmentOptions({
    this.forceRefresh = false,
    this.enabledProviders,
  });

  final bool forceRefresh;
  final List<String>? enabledProviders;
}

class EnrichmentContext {
  const EnrichmentContext({
    required this.prospectId,
    required this.knownData,
    this.campaignId,
    this.options = const EnrichmentOptions(),
  });

  final String prospectId;
  final String? campaignId;
  final EnrichmentKnownData knownData;
  final EnrichmentOptions options;
}

class ProviderEnrichmentResult {
  const ProviderEnrichmentResult({
    required this.provider,
    required this.status,
    required this.fetchedAt,
    this.data = const {},
    this.signals = const [],
    this.confidence,
    this.expiresAt,
    this.error,
    this.durationMs,
    this.cacheStatus = CacheStatus.none,
  });

  final String provider;
  final ProviderStatus status;
  final Map<String, Object?> data;
  final List<EnrichmentSignal> signals;
  final double? confidence;
  final DateTime fetchedAt;
  final DateTime? expiresAt;
  final ProviderError? error;
  final int? durationMs;
  final CacheStatus cacheStatus;
}

/// Aligné sur `runProviderSafe` / `shouldEmitSignal` / BodaccProvider (Edge).
abstract final class EnrichmentContractRules {
  /// Absence de donnée ≠ signal positif.
  static bool shouldEmitSignal(Object? value) => value != null;

  /// Miroir `normalizeSiren` + `BodaccProvider.canRun`.
  static bool bodaccCanRun(EnrichmentKnownData known) {
    final digits = (known.siren ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length == 9;
  }

  /// Miroir `SireneProvider.canRun` (name + city fournis).
  static bool sireneCanRun(EnrichmentKnownData known) {
    return known.name != null && known.city != null;
  }

  /// Miroir `PlacesProvider.canRun` (ville non vide).
  static bool placesCanRun(EnrichmentKnownData known) {
    return (known.city ?? '').trim().isNotEmpty;
  }

  /// Miroir `CompanyProvider.canRun` (SIREN 9 chiffres).
  static bool companyCanRun(EnrichmentKnownData known) {
    final digits = (known.siren ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length == 9;
  }

  /// Miroir `PageSpeedProvider.canRun` (URL normalisable).
  static bool pagespeedCanRun(EnrichmentKnownData known) {
    final raw = known.websiteUrl;
    if (raw == null || raw.isEmpty) return false;
    try {
      final withScheme =
          raw.startsWith('http') ? raw : 'https://$raw';
      final u = Uri.parse(withScheme);
      return u.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Miroir `WebsiteProvider.canRun` (même prérequis URL).
  static bool websiteCanRun(EnrichmentKnownData known) =>
      pagespeedCanRun(known);

  /// Aligné métriques C3 : ssrf / timeout → failure.
  static bool websiteCountsAsApiFailure(String? errorType) =>
      errorType == 'ssrf' || errorType == 'timeout';

  /// Skip PageSpeed si analyse légère a prouvé l'injoignabilité.
  static bool pagespeedShouldSkipUnreachable(EnrichmentKnownData known) {
    return known.websiteReachable == false;
  }

  static bool isProviderEnabled(EnrichmentContext ctx, String name) {
    final list = ctx.options.enabledProviders;
    if (list == null || list.isEmpty) return true;
    return list.contains(name);
  }

  /// Simule canRun false / disabled → skipped (sans appeler enrich).
  static ProviderEnrichmentResult skipped({
    required String provider,
    required String reason,
  }) {
    return ProviderEnrichmentResult(
      provider: provider,
      status: ProviderStatus.skipped,
      fetchedAt: DateTime.now(),
      error: ProviderError(
        type: 'skipped',
        message: reason,
        retryable: false,
      ),
    );
  }

  /// Simule une exception → failed classifié.
  static ProviderEnrichmentResult failedFromThrow({
    required String provider,
    required Object err,
  }) {
    final classified = classifyThrown(err);
    return ProviderEnrichmentResult(
      provider: provider,
      status: ProviderStatus.failed,
      fetchedAt: DateTime.now(),
      error: classified,
    );
  }

  static ProviderError classifyThrown(Object err) {
    final msg = sanitizeErrorMessage(err.toString());
    final lower = msg.toLowerCase();
    if (lower.contains('timeout') || lower.contains('abort')) {
      return ProviderError(type: 'timeout', message: msg, retryable: true);
    }
    if (lower.contains('429')) {
      return ProviderError(type: 'http_429', message: msg, retryable: true);
    }
    if (lower.contains('401') || lower.contains('403')) {
      return ProviderError(type: 'http_4xx', message: msg, retryable: false);
    }
    if (lower.contains('ssrf') || lower.contains('private_ip')) {
      return ProviderError(type: 'ssrf', message: msg, retryable: false);
    }
    if (lower.contains('parse') || lower.contains('json')) {
      return ProviderError(type: 'parse', message: msg, retryable: false);
    }
    return ProviderError(type: 'other', message: msg, retryable: false);
  }

  static String sanitizeErrorMessage(String raw) {
    return raw
        .replaceAll(RegExp(r'\b\d{9}\b'), '[redacted]')
        .replaceAll(RegExp(r'\b\d{14}\b'), '[redacted]')
        .replaceAll(RegExp(r'https?:\/\/\S+', caseSensitive: false), '[url]')
        .replaceAll(
          RegExp(r'[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}', caseSensitive: false),
          '[email]',
        );
  }

  /// Clés metadata autorisées (basse cardinalité / non PII).
  static const allowedMetadataKeys = {
    'durationMs',
    'cacheStatus',
    'operation',
    'error_type',
    'status',
    'provider',
  };

  /// Miroir Edge `PROVIDER_NAMES` (hors `company` non branché en pipeline).
  static const providerNames = [
    'places',
    'sirene',
    'company',
    'bodacc',
    'website',
    'pagespeed',
  ];
}
