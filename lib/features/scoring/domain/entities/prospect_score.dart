import '../../../../core/constants/priority_level.dart';

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

  /// Offre recommandée pour ce prospect (libellé libre issu de la grille),
  /// null si le prospect est exclu ou non pertinent pour l'offre.
  final String? recommendedOffer;
  final DateTime? computedAt;
  final int scoringVersion;
  final Map<String, int> componentScores;
  final Map<String, double> subScores;
}
