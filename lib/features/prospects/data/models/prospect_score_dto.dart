import '../../../../core/constants/offer_types.dart';
import '../../../../core/constants/priority_level.dart';
import '../../../scoring/domain/entities/prospect_score.dart';

class ProspectScoreDto {
  ProspectScoreDto({
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
    this.scoringVersion = 1,
    this.componentScores = const {},
    this.subScores = const {},
  });

  factory ProspectScoreDto.fromJson(Map<String, dynamic> json) {
    final rawComponents = json['component_scores'] as Map<String, dynamic>? ?? {};
    final rawSubs = json['sub_scores'] as Map<String, dynamic>? ?? {};
    return ProspectScoreDto(
      prospectId: json['prospect_id'] as String,
      globalScore: json['global_score'] as int,
      accessibilityScore: json['accessibility_score'] as int,
      websiteOpportunity: json['website_opportunity'] as int,
      softwareOpportunity: json['software_opportunity'] as int,
      commercialHealth: json['commercial_health'] as int,
      siteScore: (json['site_score'] as num).toDouble(),
      softwareScore: (json['software_score'] as num).toDouble(),
      easyRestScore: (json['easy_rest_score'] as num).toDouble(),
      accessibilityStars: (json['accessibility_stars'] as num).toDouble(),
      digitalMaturity: (json['digital_maturity'] as num).toDouble(),
      falsePositiveRisk: (json['false_positive_risk'] as num).toDouble(),
      priority: json['priority'] as String,
      recommendedOffer: json['recommended_offer'] as String?,
      scoringVersion: json['scoring_version'] as int? ?? 1,
      componentScores: rawComponents.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
      subScores: rawSubs.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    );
  }

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
  final String priority;
  final String? recommendedOffer;
  final int scoringVersion;
  final Map<String, int> componentScores;
  final Map<String, double> subScores;

  Map<String, dynamic> toInsertJson() {
    return {
      'prospect_id': prospectId,
      'global_score': globalScore,
      'accessibility_score': accessibilityScore,
      'website_opportunity': websiteOpportunity,
      'software_opportunity': softwareOpportunity,
      'commercial_health': commercialHealth,
      'site_score': siteScore,
      'software_score': softwareScore,
      'easy_rest_score': easyRestScore,
      'accessibility_stars': accessibilityStars,
      'digital_maturity': digitalMaturity,
      'false_positive_risk': falsePositiveRisk,
      'priority': priority,
      'recommended_offer': recommendedOffer,
      'scoring_version': scoringVersion,
      'component_scores': componentScores,
      'sub_scores': subScores,
    };
  }
}

ProspectScore prospectScoreFromDto(ProspectScoreDto dto, {String? id}) {
  return ProspectScore(
    id: id ?? dto.prospectId,
    prospectId: dto.prospectId,
    globalScore: dto.globalScore,
    accessibilityScore: dto.accessibilityScore,
    websiteOpportunity: dto.websiteOpportunity,
    softwareOpportunity: dto.softwareOpportunity,
    commercialHealth: dto.commercialHealth,
    siteScore: dto.siteScore,
    softwareScore: dto.softwareScore,
    easyRestScore: dto.easyRestScore,
    accessibilityStars: dto.accessibilityStars,
    digitalMaturity: dto.digitalMaturity,
    falsePositiveRisk: dto.falsePositiveRisk,
    priority: PriorityLevel.fromDb(dto.priority),
    recommendedOffer: dto.recommendedOffer != null
        ? OfferType.fromDb(dto.recommendedOffer!)
        : null,
    computedAt: DateTime.now(),
    scoringVersion: dto.scoringVersion,
    componentScores: dto.componentScores,
    subScores: dto.subScores,
  );
}

ProspectScoreDto prospectScoreToDto(ProspectScore score) {
  return ProspectScoreDto(
    prospectId: score.prospectId,
    globalScore: score.globalScore,
    accessibilityScore: score.accessibilityScore,
    websiteOpportunity: score.websiteOpportunity,
    softwareOpportunity: score.softwareOpportunity,
    commercialHealth: score.commercialHealth,
    siteScore: score.siteScore,
    softwareScore: score.softwareScore,
    easyRestScore: score.easyRestScore,
    accessibilityStars: score.accessibilityStars,
    digitalMaturity: score.digitalMaturity,
    falsePositiveRisk: score.falsePositiveRisk,
    priority: score.priority.dbValue,
    recommendedOffer: score.recommendedOffer?.dbValue,
    scoringVersion: score.scoringVersion,
    componentScores: score.componentScores,
    subScores: score.subScores,
  );
}
