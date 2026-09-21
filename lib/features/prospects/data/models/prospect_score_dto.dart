import '../../../scoring/domain/entities/score_confidence.dart';
import '../../../scoring/domain/entities/score_contribution.dart';

List<ScoreContribution> _parseContributions(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => ScoreContribution.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<ScoreWarning> _parseWarnings(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => ScoreWarning.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<String> _parseStringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((e) => e.toString()).toList();
}

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
    this.confidenceScore,
    this.filledFields,
    this.totalFields,
    this.missingFields = const [],
    this.contributions = const [],
    this.scoreWarnings = const [],
    this.fitScore,
    this.opportunityScore,
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
      confidenceScore: json['confidence_score'] as int?,
      filledFields: json['filled_fields'] as int?,
      totalFields: json['total_fields'] as int?,
      missingFields: _parseStringList(json['missing_fields']),
      contributions: _parseContributions(json['contributions']),
      scoreWarnings: _parseWarnings(json['score_warnings']),
      fitScore: json['fit_score'] as int?,
      opportunityScore: json['opportunity_score'] as int?,
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
  final int? confidenceScore;
  final int? filledFields;
  final int? totalFields;
  final List<String> missingFields;
  final List<ScoreContribution> contributions;
  final List<ScoreWarning> scoreWarnings;
  final int? fitScore;
  final int? opportunityScore;

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
      'confidence_score': confidenceScore,
      'filled_fields': filledFields,
      'total_fields': totalFields,
      'missing_fields': missingFields,
      'contributions': contributions.map((c) => c.toJson()).toList(),
      'score_warnings': scoreWarnings.map((w) => w.toJson()).toList(),
      'fit_score': fitScore,
      'opportunity_score': opportunityScore,
    };
  }
}
