import 'package:uuid/uuid.dart';

import '../../../../core/constants/offer_types.dart';
import '../../../../core/constants/priority_level.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/entities/prospect_score.dart';
import 'accessibility_scorer.dart';
import 'digital_maturity_scorer.dart';
import 'easy_rest_scorer.dart';
import 'exclusion_checker.dart';

class ScoringEngine {
  ScoringEngine({
    ExclusionChecker? exclusionChecker,
    AccessibilityScorer? accessibilityScorer,
    SiteScorer? siteScorer,
    SoftwareScorer? softwareScorer,
    EasyRestScorer? easyRestScorer,
    CommercialHealthScorer? commercialHealthScorer,
    DigitalMaturityScorer? digitalMaturityScorer,
    FalsePositiveDetector? falsePositiveDetector,
  })  : _exclusion = exclusionChecker ?? ExclusionChecker(),
        _accessibility = accessibilityScorer ?? AccessibilityScorer(),
        _site = siteScorer ?? SiteScorer(),
        _software = softwareScorer ?? SoftwareScorer(),
        _easyRest = easyRestScorer ?? EasyRestScorer(),
        _commercial = commercialHealthScorer ?? CommercialHealthScorer(),
        _digital = digitalMaturityScorer ?? DigitalMaturityScorer(),
        _falsePositive = falsePositiveDetector ?? FalsePositiveDetector();

  final ExclusionChecker _exclusion;
  final AccessibilityScorer _accessibility;
  final SiteScorer _site;
  final SoftwareScorer _software;
  final EasyRestScorer _easyRest;
  final CommercialHealthScorer _commercial;
  final DigitalMaturityScorer _digital;
  final FalsePositiveDetector _falsePositive;
  final _uuid = const Uuid();

  ProspectScore compute(Prospect prospect, {OfferType? campaignOffer}) {
    final exclusion = _exclusion.check(prospect);
    final isExcluded = exclusion.isExcluded;

    final accessibility = _accessibility.scorePoints(prospect);
    final websiteOpp = _site.scorePoints(prospect);
    final softwareOpp = _software.scorePoints(prospect);
    final commercial = _commercial.scorePoints(prospect);

    final digitalMaturity = _digital.scoreStars(prospect);
    if (digitalMaturity >= 4 && !isExcluded) {
      return _buildExcludedScore(
        prospect,
        accessibility,
        websiteOpp,
        softwareOpp,
        commercial,
        digitalMaturity,
      );
    }

    final global = isExcluded
        ? 0
        : accessibility + websiteOpp + softwareOpp + commercial;

    final easyRestStars = _easyRest.scoreStars(prospect);
    final recommended = _recommendOffer(
      isExcluded: isExcluded,
      easyRestStars: easyRestStars,
      siteStars: _site.scoreStars(prospect),
      softwareStars: _software.scoreStars(prospect),
      campaignOffer: campaignOffer,
      category: prospect.category,
    );

    return ProspectScore(
      id: _uuid.v4(),
      prospectId: prospect.id,
      globalScore: global.clamp(0, 100),
      accessibilityScore: accessibility,
      websiteOpportunity: websiteOpp,
      softwareOpportunity: softwareOpp,
      commercialHealth: commercial,
      siteScore: _site.scoreStars(prospect),
      softwareScore: _software.scoreStars(prospect),
      easyRestScore: easyRestStars,
      accessibilityStars: _accessibility.scoreStars(prospect),
      digitalMaturity: digitalMaturity,
      falsePositiveRisk: _falsePositive.riskStars(
        prospect,
        isExcluded: isExcluded,
      ),
      priority: PriorityLevel.fromScore(global, isExcluded: isExcluded),
      recommendedOffer: recommended,
      computedAt: DateTime.now(),
    );
  }

  OfferType? _recommendOffer({
    required bool isExcluded,
    required double easyRestStars,
    required double siteStars,
    required double softwareStars,
    OfferType? campaignOffer,
    String? category,
  }) {
    if (isExcluded) return null;
    if (easyRestStars >= 3 &&
        ((category?.toLowerCase().contains('rest') ?? false) ||
            (category?.toLowerCase().contains('bar') ?? false))) {
      return OfferType.easyRest;
    }
    if (siteStars >= 3) return OfferType.website;
    if (softwareStars >= 3) return OfferType.businessSoftware;
    return campaignOffer ?? OfferType.crm;
  }

  ProspectScore _buildExcludedScore(
    Prospect prospect,
    int accessibility,
    int websiteOpp,
    int softwareOpp,
    int commercial,
    double digitalMaturity,
  ) {
    return ProspectScore(
      id: _uuid.v4(),
      prospectId: prospect.id,
      globalScore: 0,
      accessibilityScore: accessibility,
      websiteOpportunity: websiteOpp,
      softwareOpportunity: softwareOpp,
      commercialHealth: commercial,
      siteScore: _site.scoreStars(prospect),
      softwareScore: _software.scoreStars(prospect),
      easyRestScore: _easyRest.scoreStars(prospect),
      accessibilityStars: _accessibility.scoreStars(prospect),
      digitalMaturity: digitalMaturity,
      falsePositiveRisk: 5,
      priority: PriorityLevel.excluded,
      recommendedOffer: null,
      computedAt: DateTime.now(),
    );
  }
}
