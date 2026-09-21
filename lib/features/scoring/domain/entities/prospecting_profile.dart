import '../../../campaigns/domain/entities/campaign_target_profile.dart';
import '../measurable_criteria_catalog.dart';

/// Profil de prospection lisible (Phase 5) — validé avant génération de grille.
class ProspectingProfile {
  const ProspectingProfile({
    required this.offer,
    required this.targetSummary,
    required this.signals,
    required this.exclusions,
    this.geographyHint = '',
    this.clientSizeHint = '',
  });

  factory ProspectingProfile.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic v) {
      if (v is! List) return const [];
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .where((s) => !MeasurableCriteriaCatalog.hasForbiddenClaim(null, s))
          .toList();
    }

    return ProspectingProfile(
      offer: (json['offer'] as String?)?.trim() ?? '',
      targetSummary: (json['target_summary'] as String?)?.trim() ?? '',
      signals: list(json['signals']),
      exclusions: list(json['exclusions']),
      geographyHint: (json['geography_hint'] as String?)?.trim() ?? '',
      clientSizeHint: (json['client_size_hint'] as String?)?.trim() ?? '',
    );
  }

  final String offer;
  final String targetSummary;
  final List<String> signals;
  final List<String> exclusions;
  final String geographyHint;
  final String clientSizeHint;

  Map<String, dynamic> toJson() => {
        'offer': offer,
        'target_summary': targetSummary,
        'signals': signals,
        'exclusions': exclusions,
        'geography_hint': geographyHint,
        'client_size_hint': clientSizeHint,
      };

  /// Payload Edge compatible avec l'ancien commercialProfile (prompt grille).
  Map<String, dynamic> toCommercialProfilePayload() => {
        'offer': offer,
        'target_client_type': targetSummary,
        'positive_signals': signals.join(' ; '),
        'exclusion_criteria': exclusions.join(' ; '),
        'service_area': geographyHint,
        'client_size': clientSizeHint,
      };

  ProspectingProfile copyWith({
    String? offer,
    String? targetSummary,
    List<String>? signals,
    List<String>? exclusions,
    String? geographyHint,
    String? clientSizeHint,
  }) {
    return ProspectingProfile(
      offer: offer ?? this.offer,
      targetSummary: targetSummary ?? this.targetSummary,
      signals: signals ?? this.signals,
      exclusions: exclusions ?? this.exclusions,
      geographyHint: geographyHint ?? this.geographyHint,
      clientSizeHint: clientSizeHint ?? this.clientSizeHint,
    );
  }

  /// Propagation vers le Target Profile campagne (Phase 10) — pas de duplication
  /// de saisie ; les campagnes existantes restent inchangées tant qu'on n'applique pas.
  CampaignTargetProfile toCampaignTargetProfile() {
    return CampaignTargetProfile(
      offerSummary: offer,
      targetSummary: targetSummary,
      signalsSought: signals,
      exclusions: exclusions,
      clientSizeHint: clientSizeHint,
      geographyNote: geographyHint,
    );
  }
}
