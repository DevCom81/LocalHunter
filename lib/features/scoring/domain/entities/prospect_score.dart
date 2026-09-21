import '../../../../core/constants/priority_level.dart';
import 'score_confidence.dart';
import 'score_contribution.dart';

class ProspectScore {
  const ProspectScore({
    required this.id,
    required this.prospectId,
    required this.globalScore,
    required this.accessibilityScore,
    required this.websiteOpportunity,
    required this.softwareOpportunity,
    required this.commercialHealth,
    required this.siteScore,
    required this.softwareScore,
    required this.easyRestScore,
    required this.accessibilityStars,
    required this.digitalMaturity,
    required this.falsePositiveRisk,
    required this.priority,
    this.recommendedOffer,
    this.computedAt,
    this.scoringVersion = 1,
    this.componentScores = const {},
    this.subScores = const {},
    this.confidenceScore,
    this.filledFields,
    this.totalFields,
    this.missingFields = const [],
    this.explanationContributions = const [],
    this.explanationWarnings = const [],
    this.fitScore,
    this.opportunityScore,
  });

  final String id;
  final String prospectId;
  final int globalScore;
  final int accessibilityScore;
  final int websiteOpportunity;
  final int softwareOpportunity;
  final int commercialHealth;
  final double siteScore;
  final double softwareScore;
  final double easyRestScore;
  final double accessibilityStars;
  final double digitalMaturity;
  final double falsePositiveRisk;
  final PriorityLevel priority;
  final String? recommendedOffer;
  final DateTime? computedAt;
  final int scoringVersion;
  final Map<String, int> componentScores;
  final Map<String, double> subScores;

  /// Snapshot d'explicabilité (B1) — null = score pré-B1, recalcul à la volée.
  final int? confidenceScore;
  final int? filledFields;
  final int? totalFields;
  final List<String> missingFields;
  final List<ScoreContribution> explanationContributions;
  final List<ScoreWarning> explanationWarnings;

  /// Correspondance cible (FIT) 0–100 — null si non calculé / pré-Phase 8.
  final int? fitScore;

  /// Opportunité / timing 0–100 — null si aucun critère OPP ou pré-Phase 8.
  final int? opportunityScore;

  ProspectScore copyWith({
    int? scoringVersion,
    int? confidenceScore,
    int? filledFields,
    int? totalFields,
    List<String>? missingFields,
    List<ScoreContribution>? explanationContributions,
    List<ScoreWarning>? explanationWarnings,
    int? fitScore,
    int? opportunityScore,
    bool clearFitOpportunity = false,
  }) {
    return ProspectScore(
      id: id,
      prospectId: prospectId,
      globalScore: globalScore,
      accessibilityScore: accessibilityScore,
      websiteOpportunity: websiteOpportunity,
      softwareOpportunity: softwareOpportunity,
      commercialHealth: commercialHealth,
      siteScore: siteScore,
      softwareScore: softwareScore,
      easyRestScore: easyRestScore,
      accessibilityStars: accessibilityStars,
      digitalMaturity: digitalMaturity,
      falsePositiveRisk: falsePositiveRisk,
      priority: priority,
      recommendedOffer: recommendedOffer,
      computedAt: computedAt,
      scoringVersion: scoringVersion ?? this.scoringVersion,
      componentScores: componentScores,
      subScores: subScores,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      filledFields: filledFields ?? this.filledFields,
      totalFields: totalFields ?? this.totalFields,
      missingFields: missingFields ?? this.missingFields,
      explanationContributions:
          explanationContributions ?? this.explanationContributions,
      explanationWarnings: explanationWarnings ?? this.explanationWarnings,
      fitScore: clearFitOpportunity ? null : (fitScore ?? this.fitScore),
      opportunityScore: clearFitOpportunity
          ? null
          : (opportunityScore ?? this.opportunityScore),
    );
  }
}
