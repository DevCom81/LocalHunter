import '../../../../core/constants/offer_types.dart';
import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/grid_config.dart';
import '../../domain/entities/scoring_grid.dart';
import '../engine/configurable_exclusion_checker.dart';
import '../engine/configurable_scoring_engine.dart';

class DefaultScoringGrids {
  static const defaultId = 'grid-localhunter-default';
  static const easyRestId = 'grid-easyrest';
  static const demoCampaignGridId = 'grid-demo-albi';

  static ScoringGrid localHunterDefault({String userId = ''}) {
    return ScoringGrid(
      id: defaultId,
      userId: userId,
      name: 'LocalHunter Default',
      isTemplate: true,
      exclusionConfig: defaultExclusionConfig(),
      recommendationConfig: defaultRecommendationConfig(),
      criteria: [
        _component('accessibility', 'Décisionnaire accessible', 30),
        _component('website_opportunity', 'Opportunité site web', 30),
        _component('software_opportunity', 'Opportunité logiciel métier', 25),
        _component('commercial_health', 'Santé commerciale', 15),
        _subScore('site_score', 'SiteScore', 5),
        _subScore('software_score', 'SoftwareScore', 5),
        _subScore('easy_rest_score', 'EasyRestScore', 5),
        _subScore('accessibility_stars', 'Accessibilité', 5),
        _subScore('digital_maturity', 'Maturité digitale', 5),
        _subScore('false_positive_risk', 'Risque faux positif', 5),
      ],
    );
  }

  static ScoringGrid easyRest({String userId = ''}) {
    final base = localHunterDefault(userId: userId);
    return base.copyWith(
      id: easyRestId,
      name: 'EasyRest Restauration',
      criteria: base.criteria.map((c) {
        if (c.key == 'software_opportunity') return c.copyWith(maxPoints: 15);
        if (c.key == 'website_opportunity') return c.copyWith(maxPoints: 20);
        if (c.key == 'easy_rest_score') return c.copyWith(starMultiplier: 1.2);
        return c;
      }).toList(),
    );
  }

  static ScoringCriterion _component(String key, String label, int max) {
    return ScoringCriterion(
      key: key,
      label: label,
      kind: CriterionKind.component,
      maxPoints: max,
      rule: CriterionRule(type: CriterionRuleType.legacy, scorerKey: key),
    );
  }

  static ScoringCriterion _subScore(String key, String label, int max) {
    return ScoringCriterion(
      key: key,
      label: label,
      kind: CriterionKind.subScore,
      maxPoints: max,
      rule: CriterionRule(type: CriterionRuleType.legacy, scorerKey: key),
    );
  }

  static ScoringGrid? resolveDefault(List<ScoringGrid> grids) {
    for (final name in ['LocalHunter Default', 'EasyRest Restauration']) {
      final match = grids.where((g) => g.name == name).firstOrNull;
      if (match != null) return match;
    }
    return grids.firstOrNull;
  }

  static ScoringGrid? forOfferType(List<ScoringGrid> grids, OfferType offer) {
    final name = offer == OfferType.easyRest
        ? 'EasyRest Restauration'
        : 'LocalHunter Default';
    return grids.where((g) => g.name == name).firstOrNull ??
        resolveDefault(grids);
  }

  static ScoringGrid blank({required String userId, String name = 'Nouvelle grille'}) {
    return ScoringGrid(
      id: '',
      userId: userId,
      name: name,
      description: '',
      isTemplate: false,
      exclusionConfig: defaultExclusionConfig(),
      recommendationConfig: const GridRecommendationConfig(),
      criteria: [
        ScoringCriterion(
          key: 'criterion_1',
          label: 'Critère 1',
          kind: CriterionKind.component,
          maxPoints: 25,
          rule: CriterionRule(
            type: CriterionRuleType.prospectField,
            field: 'phone',
            presenceOnly: true,
          ),
        ),
      ],
    );
  }

  static ScoringGrid duplicateFrom(
    ScoringGrid source, {
    required String userId,
    String? name,
    bool asTemplate = false,
  }) {
    return ScoringGrid(
      id: '',
      userId: userId,
      name: name ?? '${source.name} (copie)',
      description: source.description,
      isTemplate: asTemplate,
      exclusionConfig: source.exclusionConfig,
      recommendationConfig: source.recommendationConfig,
      criteria: source.criteria
          .map(
            (c) => ScoringCriterion(
              key: c.key,
              label: c.label,
              kind: c.kind,
              maxPoints: c.maxPoints,
              starMultiplier: c.starMultiplier,
              isActive: c.isActive,
              rule: c.rule,
            ),
          )
          .toList(),
    );
  }
}
