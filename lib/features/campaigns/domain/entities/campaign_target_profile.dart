/// Profil de cible commercial porté par une campagne (Phase 7).
///
/// Optionnel et indépendant de la géographie Places (ville / rayon).
class CampaignTargetProfile {
  const CampaignTargetProfile({
    this.offerSummary = '',
    this.targetSummary = '',
    this.signalsSought = const [],
    this.exclusions = const [],
    this.clientSizeHint = '',
    this.geographyNote = '',
  });

  factory CampaignTargetProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const CampaignTargetProfile();
    }
    List<String> list(dynamic v) {
      if (v is! List) return const [];
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return CampaignTargetProfile(
      offerSummary: (json['offer_summary'] as String?)?.trim() ?? '',
      targetSummary: (json['target_summary'] as String?)?.trim() ?? '',
      signalsSought: list(json['signals_sought']),
      exclusions: list(json['exclusions']),
      clientSizeHint: (json['client_size_hint'] as String?)?.trim() ?? '',
      geographyNote: (json['geography_note'] as String?)?.trim() ?? '',
    );
  }

  final String offerSummary;
  final String targetSummary;
  final List<String> signalsSought;
  final List<String> exclusions;
  final String clientSizeHint;

  /// Note libre (département, région…) — ne remplace pas city/radius.
  final String geographyNote;

  bool get isEmpty =>
      offerSummary.isEmpty &&
      targetSummary.isEmpty &&
      signalsSought.isEmpty &&
      exclusions.isEmpty &&
      clientSizeHint.isEmpty &&
      geographyNote.isEmpty;

  Map<String, dynamic> toJson() => {
        'offer_summary': offerSummary,
        'target_summary': targetSummary,
        'signals_sought': signalsSought,
        'exclusions': exclusions,
        'client_size_hint': clientSizeHint,
        'geography_note': geographyNote,
      };
}
