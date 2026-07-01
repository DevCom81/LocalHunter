import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/scoring_grid.dart';
import 'accessibility_scorer.dart';
import 'digital_maturity_scorer.dart';
import 'easy_rest_scorer.dart';
import 'prospect_field_resolver.dart';

class LegacyScorerRegistry {
  LegacyScorerRegistry({
    AccessibilityScorer? accessibility,
    SiteScorer? site,
    SoftwareScorer? software,
    EasyRestScorer? easyRest,
    CommercialHealthScorer? commercial,
    DigitalMaturityScorer? digital,
    FalsePositiveDetector? falsePositive,
  })  : _accessibility = accessibility ?? AccessibilityScorer(),
        _site = site ?? SiteScorer(),
        _software = software ?? SoftwareScorer(),
        _easyRest = easyRest ?? EasyRestScorer(),
        _commercial = commercial ?? CommercialHealthScorer(),
        _digital = digital ?? DigitalMaturityScorer(),
        _falsePositive = falsePositive ?? FalsePositiveDetector();

  final AccessibilityScorer _accessibility;
  final SiteScorer _site;
  final SoftwareScorer _software;
  final EasyRestScorer _easyRest;
  final CommercialHealthScorer _commercial;
  final DigitalMaturityScorer _digital;
  final FalsePositiveDetector _falsePositive;

  static const defaultMax = <String, int>{
    'accessibility': 30,
    'website_opportunity': 30,
    'software_opportunity': 25,
    'commercial_health': 15,
  };

  int componentPoints(Prospect prospect, String key) {
    switch (key) {
      case 'accessibility':
        return _accessibility.scorePoints(prospect);
      case 'website_opportunity':
        return _site.scorePoints(prospect);
      case 'software_opportunity':
        return _software.scorePoints(prospect);
      case 'commercial_health':
        return _commercial.scorePoints(prospect);
      default:
        return 0;
    }
  }

  double subScoreStars(Prospect prospect, String key, {bool isExcluded = false}) {
    switch (key) {
      case 'site_score':
        return _site.scoreStars(prospect);
      case 'software_score':
        return _software.scoreStars(prospect);
      case 'easy_rest_score':
        return _easyRest.scoreStars(prospect);
      case 'accessibility_stars':
        return _accessibility.scoreStars(prospect);
      case 'digital_maturity':
        return _digital.scoreStars(prospect);
      case 'false_positive_risk':
        return _falsePositive.riskStars(prospect, isExcluded: isExcluded);
      default:
        return 0;
    }
  }

  int defaultMaxFor(String key) => defaultMax[key] ?? 0;
}

class RuleBasedScorer {
  RuleBasedScorer({LegacyScorerRegistry? legacy})
      : _legacy = legacy ?? LegacyScorerRegistry();

  final LegacyScorerRegistry _legacy;

  int scoreComponent(Prospect prospect, ScoringCriterion criterion) {
    if (!criterion.isActive) return 0;
    final raw = _rawComponent(prospect, criterion);
    final defaultMax = _legacy.defaultMaxFor(criterion.key);
    if (defaultMax > 0) {
      return _scaleInt(raw, defaultMax, criterion.maxPoints);
    }
    return raw.clamp(0, criterion.maxPoints);
  }

  double scoreSubScore(
    Prospect prospect,
    ScoringCriterion criterion, {
    bool isExcluded = false,
  }) {
    if (!criterion.isActive) return 0;
    final raw = _rawSubScore(prospect, criterion, isExcluded: isExcluded);
    return (raw * criterion.starMultiplier).clamp(0, criterion.maxPoints.toDouble());
  }

  int _rawComponent(Prospect prospect, ScoringCriterion criterion) {
    final rule = criterion.rule;
    switch (rule.type) {
      case CriterionRuleType.legacy:
        return _legacy.componentPoints(prospect, criterion.key);
      case CriterionRuleType.prospectField:
        return _scoreFieldPresence(prospect, rule, criterion.maxPoints);
      case CriterionRuleType.boolean:
        return _scoreBoolean(prospect, rule, criterion.maxPoints);
      case CriterionRuleType.threshold:
        return _scoreThreshold(prospect, rule, criterion.maxPoints);
      case CriterionRuleType.keywordMatch:
        return _scoreKeyword(prospect, rule, criterion.maxPoints);
    }
  }

  double _rawSubScore(
    Prospect prospect,
    ScoringCriterion criterion, {
    required bool isExcluded,
  }) {
    final rule = criterion.rule;
    switch (rule.type) {
      case CriterionRuleType.legacy:
        return _legacy.subScoreStars(
          prospect,
          criterion.key,
          isExcluded: isExcluded,
        );
      case CriterionRuleType.prospectField:
        return hasField(prospect, rule)
            ? criterion.maxPoints.toDouble()
            : 0;
      case CriterionRuleType.boolean:
        return _matchesBoolean(prospect, rule)
            ? criterion.maxPoints.toDouble()
            : 0;
      case CriterionRuleType.threshold:
        final scaled = _scoreThreshold(prospect, rule, criterion.maxPoints);
        return scaled.toDouble();
      case CriterionRuleType.keywordMatch:
        final scaled = _scoreKeyword(prospect, rule, criterion.maxPoints);
        return scaled.toDouble();
    }
  }

  int _scoreFieldPresence(
    Prospect prospect,
    CriterionRule rule,
    int maxPoints,
  ) {
    if (rule.field == null) return 0;
    return hasField(prospect, rule) ? maxPoints : 0;
  }

  int _scoreBoolean(Prospect prospect, CriterionRule rule, int maxPoints) {
    return _matchesBoolean(prospect, rule) ? maxPoints : 0;
  }

  bool _matchesBoolean(Prospect prospect, CriterionRule rule) {
    if (rule.field == null) return false;
    if (rule.presenceOnly) return hasField(prospect, rule);
    final value = ProspectFieldResolver.getString(prospect, rule.field!);
    if (value == null || rule.match == null) return false;
    return value.toLowerCase().contains(rule.match!.toLowerCase());
  }

  int _scoreThreshold(
    Prospect prospect,
    CriterionRule rule,
    int maxPoints,
  ) {
    if (rule.field == null || rule.threshold == null) return 0;
    final value = ProspectFieldResolver.getNumeric(prospect, rule.field!);
    if (value == null) return 0;
    if (value < rule.threshold!) return 0;
    final ratio = (value / rule.threshold!).clamp(0, 2);
    return (ratio * maxPoints / 2).round().clamp(0, maxPoints);
  }

  int _scoreKeyword(Prospect prospect, CriterionRule rule, int maxPoints) {
    if (rule.match == null) return 0;
    final needle = rule.match!.toLowerCase();
    final haystack = '${prospect.name} ${prospect.category ?? ''}'.toLowerCase();
    return haystack.contains(needle) ? maxPoints : 0;
  }

  bool hasField(Prospect prospect, CriterionRule rule) {
    if (rule.field == null) return false;
    return ProspectFieldResolver.hasValue(prospect, rule.field!);
  }

  int _scaleInt(int raw, int defaultMax, int targetMax) {
    if (defaultMax <= 0) return raw.clamp(0, targetMax);
    return ((raw / defaultMax) * targetMax).round().clamp(0, targetMax);
  }
}
