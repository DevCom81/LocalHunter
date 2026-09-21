import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/grid_config.dart';
import '../../domain/entities/scoring_grid.dart';
import '../engine/configurable_exclusion_checker.dart';

/// Template neutre B2B (Phase 10) — aucun biais site / SEO / logiciel / CHR.
///
/// Les grilles déjà en base ne sont pas modifiées. Ce template ne s'applique
/// qu'aux nouvelles copies / catalogue / démo.
class DefaultScoringGrids {
  static const defaultId = 'grid-localhunter-default';
  static const demoCampaignGridId = 'grid-demo-albi';

  static ScoringGrid localHunterDefault({String userId = ''}) {
    return ScoringGrid(
      id: defaultId,
      userId: userId,
      name: 'LocalHunter Default',
      offerLabel: '',
      isTemplate: true,
      exclusionConfig: _neutralExclusionConfig(),
      recommendationConfig: const GridRecommendationConfig(),
      criteria: [
        _field('contact_phone', 'Téléphone disponible', 'phone', 25),
        _field('contact_email', 'Email disponible', 'email', 20),
        _field('contact_manager', 'Dirigeant / responsable identifié', 'manager_name', 15),
        _field('identity_siret', 'SIRET identifié', 'siret', 15),
        _field('activity_naf', 'Code NAF / activité renseigné', 'naf_code', 10),
        _field(
          'finance_revenue',
          'Chiffre d\'affaires connu',
          'annual_revenue',
          15,
        ),
        // BODACC : activables (poids 0) — pas de biais timing par défaut.
        _bodaccBool(
          'bodacc_accounts_filing',
          'BODACC — dépôt de comptes',
          'bodacc_has_accounts_filing',
          matchTrue: true,
        ),
        _bodaccBool(
          'bodacc_sale',
          'BODACC — vente / cession',
          'bodacc_has_sale',
          matchTrue: true,
        ),
        _bodaccBool(
          'bodacc_creation',
          'BODACC — création récente',
          'bodacc_has_creation',
          matchTrue: true,
        ),
        _bodaccBool(
          'bodacc_no_collective',
          'BODACC — sans procédure collective',
          'bodacc_has_collective_proceeding',
          matchTrue: false,
        ),
      ],
    );
  }

  /// Exclusions B2B sans pattern site ni maturité digitale.
  static GridExclusionConfig _neutralExclusionConfig() {
    final base = defaultExclusionConfig();
    return GridExclusionConfig(
      rules: base.rules
          .where(
            (r) =>
                r.type != 'website_pattern' &&
                r.type != 'sub_score_threshold',
          )
          .toList(),
    );
  }

  static ScoringCriterion _field(
    String key,
    String label,
    String field,
    int max,
  ) {
    return ScoringCriterion(
      key: key,
      label: label,
      kind: CriterionKind.component,
      maxPoints: max,
      rule: CriterionRule(
        type: CriterionRuleType.prospectField,
        field: field,
        presenceOnly: true,
      ),
    );
  }

  static ScoringCriterion _bodaccBool(
    String key,
    String label,
    String field, {
    required bool matchTrue,
  }) {
    return ScoringCriterion(
      key: key,
      label: label,
      kind: CriterionKind.component,
      maxPoints: 0,
      rule: CriterionRule(
        type: CriterionRuleType.boolean,
        field: field,
        match: matchTrue ? 'true' : 'false',
        presenceOnly: false,
      ),
    );
  }

  static ScoringGrid? resolveDefault(List<ScoringGrid> grids) {
    final match =
        grids.where((g) => g.name == 'LocalHunter Default').firstOrNull;
    if (match != null) return match;
    final untitled =
        grids.where((g) => g.offerLabel.trim().isEmpty).firstOrNull;
    return untitled ?? grids.firstOrNull;
  }

  static ScoringGrid blank({
    required String userId,
    String name = 'Nouvelle grille',
  }) {
    return ScoringGrid(
      id: '',
      userId: userId,
      name: name,
      description: '',
      isTemplate: false,
      exclusionConfig: _neutralExclusionConfig(),
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
      offerLabel: source.offerLabel,
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
