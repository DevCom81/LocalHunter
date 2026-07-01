import '../../../../core/constants/offer_types.dart';
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
  final OfferType? recommendedOffer;
  final DateTime? computedAt;
  final int scoringVersion;
  final Map<String, int> componentScores;
  final Map<String, double> subScores;
}
