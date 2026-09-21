/// Niveau épistémique d'une information commerciale.
///
/// - [fact] : directement issu d'une source (SIRENE, Places, BODACC, …).
/// - [signal] : interprétation commerciale déterministe d'un ou plusieurs faits.
/// - [inference] : déduction non prouvée (ne jamais présenter comme vérité).
enum SignalKind { fact, signal, inference }

/// Signal générique exploitable pour scoring / explicabilité (Phase 4).
///
/// Stockage : dérivé à la volée depuis [Prospect] — pas de table SQL pour l'instant.
class ProspectSignal {
  const ProspectSignal({
    required this.type,
    required this.label,
    required this.value,
    required this.source,
    required this.kind,
    required this.confidence,
    this.observedAt,
  });

  /// Clé stable (ex. `COMPANY_AGE`, `BODACC_HAS_SALE`).
  final String type;

  /// Libellé commercial court (FR).
  final String label;

  /// Valeur affichable (bool, nombre, texte).
  final Object value;

  /// Source de données (`SIRENE`, `PLACES`, `BODACC`, `COMPANY`, …).
  final String source;

  final SignalKind kind;

  /// 0.0–1.0 — faits sources ≈ 1.0 ; signaux dérivés souvent 1.0 si déterministes.
  final double confidence;

  final DateTime? observedAt;

  String get kindLabel => switch (kind) {
        SignalKind.fact => 'Fait',
        SignalKind.signal => 'Signal',
        SignalKind.inference => 'Hypothèse',
      };

  String get displayValue {
    final v = value;
    if (v is bool) return v ? 'Oui' : 'Non';
    return v.toString();
  }
}
