import 'package:flutter_test/flutter_test.dart';

import 'package:localhunter/features/prospects/domain/enrichment/enrichment_needs.dart';
import 'package:localhunter/features/scoring/data/engine/prospect_field_resolver.dart';
import 'package:localhunter/features/scoring/data/grids/default_scoring_grids.dart';
import 'package:localhunter/features/scoring/domain/entities/criterion_rule.dart';
import 'package:localhunter/features/scoring/domain/entities/grid_config.dart';
import 'package:localhunter/features/scoring/domain/entities/scoring_grid.dart';

/// Phase 10 — cohérence pipeline (scénarios A–D sans hardcoder les métiers).
void main() {
  group('Default neutre B2B', () {
    test('aucun critère web / logiciel / EasyRest / digital pondéré', () {
      final grid = DefaultScoringGrids.localHunterDefault();
      final weighted = grid.criteria.where((c) => c.isActive && c.maxPoints > 0);
      final keys = weighted.map((c) => c.key).toSet();
      final fields = weighted.map((c) => c.rule.field).whereType<String>().toSet();

      expect(keys.any((k) => k.contains('website') || k.contains('site_score')), isFalse);
      expect(keys.any((k) => k.contains('software') || k.contains('easy_rest')), isFalse);
      expect(keys.contains('digital_maturity'), isFalse);
      expect(fields.contains('pagespeed_score'), isFalse);
      expect(grid.recommendationConfig.rules, isEmpty);

      final needs = EnrichmentNeeds.fromGrid(grid);
      expect(needs.pagespeed, isFalse);
      expect(needs.website, isFalse);
      expect(needs.sirene, isTrue);
      expect(needs.company, isTrue);
    });
  });

  group('Champs effectif / établissements', () {
    test('résolveur connaît employee_count et establishment_count', () {
      expect(ProspectFieldResolver.knownFields.contains('employee_count'), isTrue);
      expect(
        ProspectFieldResolver.knownFields.contains('establishment_count'),
        isTrue,
      );
    });
  });

  group('Scénarios offre → EnrichmentNeeds', () {
    ScoringGrid gridWith(List<ScoringCriterion> criteria) {
      return ScoringGrid(
        id: 't',
        userId: 'u',
        name: 't',
        criteria: criteria,
        exclusionConfig: const GridExclusionConfig(),
        recommendationConfig: const GridRecommendationConfig(),
      );
    }

    ScoringCriterion field(String key, String field, int max) {
      final isHeadcount = field == 'employee_count';
      return ScoringCriterion(
        key: key,
        label: key,
        kind: CriterionKind.component,
        maxPoints: max,
        rule: CriterionRule(
          type: isHeadcount
              ? CriterionRuleType.threshold
              : CriterionRuleType.prospectField,
          field: field,
          presenceOnly: !isHeadcount,
          threshold: isHeadcount ? 50 : null,
        ),
      );
    }

    test('A/B/C flotte-like : NAF + effectif + finance → pas PageSpeed', () {
      final grid = gridWith([
        field('naf', 'naf_code', 20),
        field('eff', 'employee_count', 30),
        field('eta', 'establishment_count', 15),
        field('ca', 'annual_revenue', 20),
        field('phone', 'phone', 15),
      ]);
      final needs = EnrichmentNeeds.fromGrid(grid);
      expect(needs.pagespeed, isFalse);
      expect(needs.website, isFalse);
      expect(needs.company, isTrue);
    });

    test('D agence web : website_opportunity → PageSpeed', () {
      final grid = gridWith([
        ScoringCriterion(
          key: 'website_opportunity',
          label: 'Site',
          kind: CriterionKind.component,
          maxPoints: 40,
          rule: const CriterionRule(
            type: CriterionRuleType.legacy,
            scorerKey: 'website_opportunity',
          ),
        ),
        field('phone', 'phone', 60),
      ]);
      final needs = EnrichmentNeeds.fromGrid(grid);
      expect(needs.pagespeed, isTrue);
      expect(needs.website, isTrue);
    });
  });
}
