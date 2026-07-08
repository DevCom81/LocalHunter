import 'package:uuid/uuid.dart';

import '../../../../core/constants/priority_level.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/entities/grid_config.dart';
import '../../domain/entities/prospect_score.dart';
import '../../domain/entities/scoring_grid.dart';
import 'configurable_exclusion_checker.dart';
import 'rule_based_scorer.dart';

class ConfigurableScoringEngine {
  ConfigurableScoringEngine({
    required ScoringGrid grid,
    RuleBasedScorer? scorer,
  })  : _grid = grid,
        _scorer = scorer ?? RuleBasedScorer();

  final ScoringGrid _grid;
  final RuleBasedScorer _scorer;
  final _uuid = const Uuid();

  ProspectScore compute(Prospect prospect) {
    final subScoreMap = <String, double>{};
    for (final c in _grid.criteria) {
      if (c.kind == CriterionKind.subScore && c.isActive) {
        subScoreMap[c.key] = _scorer.scoreSubScore(
          prospect,
          c,
          isExcluded: prospect.isExcluded,
        );
      }
    }

    final exclusionChecker = ConfigurableExclusionChecker(
      config: _grid.exclusionConfig,
      subScores: subScoreMap,
    );
    final exclusion = exclusionChecker.check(prospect);
    final isExcluded = prospect.isExcluded || exclusion.isExcluded;

    if (isExcluded) {
      subScoreMap.updateAll((_, v) => v);
      for (final c in _grid.criteria) {
        if (c.kind == CriterionKind.subScore && c.isActive) {
          subScoreMap[c.key] = _scorer.scoreSubScore(prospect, c, isExcluded: true);
        }
      }
    }

    var componentTotal = 0;
    final componentMap = <String, int>{};
    for (final c in _grid.criteria) {
      if (c.kind == CriterionKind.component && c.isActive) {
        final pts = isExcluded ? 0 : _scorer.scoreComponent(prospect, c);
        componentMap[c.key] = pts;
        componentTotal += pts;
      }
    }

    final global = isExcluded
        ? 0
        : (_grid.totalMax > 0
                ? (componentTotal / _grid.totalMax * 100).round()
                : componentTotal)
            .clamp(0, 100);

    final recommended = _recommendOffer(
      isExcluded: isExcluded,
      subScores: subScoreMap,
      category: prospect.category,
    );

    return _buildScore(
      prospect: prospect,
      global: global,
      isExcluded: isExcluded,
      componentMap: componentMap,
      subScoreMap: subScoreMap,
      recommended: recommended,
    );
  }

  /// L'offre recommandée est celle de la grille ([ScoringGrid.offerLabel]).
  /// Sans règle de recommandation, elle est proposée à tout prospect non
  /// exclu ; avec règles, uniquement si l'une d'elles est satisfaite.
  String? _recommendOffer({
    required bool isExcluded,
    required Map<String, double> subScores,
    String? category,
  }) {
    if (isExcluded) return null;
    final offer = _grid.offerLabel.isNotEmpty ? _grid.offerLabel : _grid.name;
    if (_grid.recommendationConfig.rules.isEmpty) return offer;
    for (final rule in _grid.recommendationConfig.rules) {
      final stars = subScores[rule.criterionKey] ?? 0;
      if (stars < rule.minStars) continue;
      if (rule.categoryKeyword != null) {
        final cat = category?.toLowerCase() ?? '';
        if (!cat.contains(rule.categoryKeyword!.toLowerCase())) continue;
      }
      return offer;
    }
    return null;
  }

  ProspectScore _buildScore({
    required Prospect prospect,
    required int global,
    required bool isExcluded,
    required Map<String, int> componentMap,
    required Map<String, double> subScoreMap,
    required String? recommended,
  }) {
    return ProspectScore(
      id: _uuid.v4(),
      prospectId: prospect.id,
      globalScore: global,
      accessibilityScore: componentMap['accessibility'] ?? 0,
      websiteOpportunity: componentMap['website_opportunity'] ?? 0,
      softwareOpportunity: componentMap['software_opportunity'] ?? 0,
      commercialHealth: componentMap['commercial_health'] ?? 0,
      siteScore: subScoreMap['site_score'] ?? 0,
      softwareScore: subScoreMap['software_score'] ?? 0,
      easyRestScore: subScoreMap['easy_rest_score'] ?? 0,
      accessibilityStars: subScoreMap['accessibility_stars'] ?? 0,
      digitalMaturity: subScoreMap['digital_maturity'] ?? 0,
      falsePositiveRisk: subScoreMap['false_positive_risk'] ??
          (isExcluded ? 5.0 : 0),
      priority: PriorityLevel.fromScore(global, isExcluded: isExcluded),
      recommendedOffer: recommended,
      computedAt: DateTime.now(),
      scoringVersion: 3,
      componentScores: componentMap,
      subScores: subScoreMap,
    );
  }
}

GridRecommendationConfig defaultRecommendationConfig() {
  return const GridRecommendationConfig(
    rules: [
      RecommendationRule(criterionKey: 'site_score', minStars: 3),
      RecommendationRule(criterionKey: 'software_score', minStars: 3),
    ],
  );
}
