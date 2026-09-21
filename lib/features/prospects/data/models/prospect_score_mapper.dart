import '../../../../core/constants/priority_level.dart';
import '../../../scoring/domain/entities/prospect_score.dart';
import 'prospect_score_dto.dart';

/// Valeurs héritées de l'ancien enum offer_type (scores calculés avant la
/// migration 007) : réaffichées avec un libellé lisible.
const _legacyOfferLabels = {
  'website': 'Site web',
  'business_software': 'Logiciel métier',
  'easy_rest': 'Restauration',
  'crm': 'CRM',
};

String? _displayOffer(String? raw) {
  if (raw == null) return null;
  return _legacyOfferLabels[raw] ?? raw;
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
    recommendedOffer: _displayOffer(dto.recommendedOffer),
    computedAt: DateTime.now(),
    scoringVersion: dto.scoringVersion,
    componentScores: dto.componentScores,
    subScores: dto.subScores,
    confidenceScore: dto.confidenceScore,
    filledFields: dto.filledFields,
    totalFields: dto.totalFields,
    missingFields: dto.missingFields,
    explanationContributions: dto.contributions,
    explanationWarnings: dto.scoreWarnings,
    fitScore: dto.fitScore,
    opportunityScore: dto.opportunityScore,
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
    recommendedOffer: score.recommendedOffer,
    scoringVersion: score.scoringVersion,
    componentScores: score.componentScores,
    subScores: score.subScores,
    confidenceScore: score.confidenceScore,
    filledFields: score.filledFields,
    totalFields: score.totalFields,
    missingFields: score.missingFields,
    contributions: score.explanationContributions,
    scoreWarnings: score.explanationWarnings,
    fitScore: score.fitScore,
    opportunityScore: score.opportunityScore,
  );
}
