import 'package:flutter_test/flutter_test.dart';

import 'package:localhunter/features/prospects/domain/enrichment/enrichment_needs.dart';
import 'package:localhunter/features/prospects/domain/entities/prospect.dart';
import 'package:localhunter/features/scoring/data/engine/prospect_field_resolver.dart';
import 'package:localhunter/features/scoring/data/services/generated_grid_parser.dart';
import 'package:localhunter/features/scoring/data/services/generated_grid_validator.dart';
import 'package:localhunter/features/scoring/domain/entities/criterion_rule.dart';
import 'package:localhunter/features/scoring/domain/entities/scoring_grid.dart';
import 'package:localhunter/features/scoring/domain/measurable_criteria_catalog.dart';

void main() {
  group('Phase 11 — whitelist mesurable', () {
    test('catalogue contient les champs Places / effectif / sociaux', () {
      expect(
        MeasurableCriteriaCatalog.measurableFields.contains('google_rating'),
        isTrue,
      );
      expect(
        MeasurableCriteriaCatalog.measurableFields.contains('employee_count'),
        isTrue,
      );
      expect(
        MeasurableCriteriaCatalog.measurableFields
            .contains('social_presence_detected'),
        isTrue,
      );
      expect(
        MeasurableCriteriaCatalog.isFieldMeasurable('possede_flotte'),
        isFalse,
      );
    });

    test('validateur rejette critères inventés / legacy', () {
      final kept = const GeneratedGridValidator().filterCriteria([
        ScoringCriterion(
          key: 'phone_ok',
          label: 'Tél',
          kind: CriterionKind.component,
          maxPoints: 50,
          rule: const CriterionRule(
            type: CriterionRuleType.prospectField,
            field: 'phone',
            presenceOnly: true,
          ),
        ),
        ScoringCriterion(
          key: 'flotte',
          label: 'A une flotte',
          kind: CriterionKind.component,
          maxPoints: 50,
          rule: const CriterionRule(
            type: CriterionRuleType.prospectField,
            field: 'possede_flotte',
            presenceOnly: true,
          ),
        ),
        ScoringCriterion(
          key: 'legacy_soft',
          label: 'Logiciel',
          kind: CriterionKind.component,
          maxPoints: 10,
          rule: const CriterionRule(
            type: CriterionRuleType.legacy,
            scorerKey: 'software_opportunity',
          ),
        ),
      ]);
      expect(kept.kept.map((c) => c.key), ['phone_ok']);
      expect(kept.rejectedKeys, containsAll(['flotte', 'legacy_soft']));
    });

    test('rejette budget / croissance même avec field whitelist', () {
      final kept = const GeneratedGridValidator().filterCriteria([
        ScoringCriterion(
          key: 'budget_ok',
          label: 'Budget suffisant',
          kind: CriterionKind.component,
          maxPoints: 50,
          rule: const CriterionRule(
            type: CriterionRuleType.threshold,
            field: 'annual_revenue',
            threshold: 100000,
          ),
        ),
        ScoringCriterion(
          key: 'growth',
          label: 'Entreprise en croissance',
          kind: CriterionKind.component,
          maxPoints: 50,
          rule: const CriterionRule(
            type: CriterionRuleType.boolean,
            field: 'company_created_recently',
            match: 'true',
          ),
        ),
        ScoringCriterion(
          key: 'ca_connu',
          label: 'CA connu',
          kind: CriterionKind.component,
          maxPoints: 100,
          rule: const CriterionRule(
            type: CriterionRuleType.prospectField,
            field: 'annual_revenue',
            presenceOnly: true,
          ),
        ),
      ]);
      expect(kept.kept.map((c) => c.key), ['ca_connu']);
      expect(kept.rejectedKeys, containsAll(['budget_ok', 'growth']));
    });

    test('parseGeneratedGrid ignore les champs hors whitelist', () {
      final grid = parseGeneratedGrid({
        'name': 'Test',
        'description': 'd',
        'criteria': [
          {
            'key': 'eff',
            'label': 'Effectif',
            'kind': 'component',
            'max_points': 100,
            'rule': {
              'type': 'threshold',
              'field': 'employee_count',
              'threshold': 50,
            },
          },
          {
            'key': 'croissance',
            'label': 'Croissance',
            'kind': 'component',
            'max_points': 20,
            'rule': {
              'type': 'prospect_field',
              'field': 'croissance_entreprise',
              'presence_only': true,
            },
          },
        ],
      }, userId: 'u');
      expect(grid.criteria.length, 1);
      expect(grid.criteria.first.rule.field, 'employee_count');
    });
  });

  group('Phase 11 — social & EnrichmentNeeds', () {
    test('grille sans social → pas de provider social', () {
      final grid = ScoringGrid(
        id: 't',
        userId: 'u',
        name: 't',
        criteria: [
          ScoringCriterion(
            key: 'phone',
            label: 'Tél',
            kind: CriterionKind.component,
            maxPoints: 100,
            rule: const CriterionRule(
              type: CriterionRuleType.prospectField,
              field: 'phone',
              presenceOnly: true,
            ),
          ),
        ],
      );
      final needs = EnrichmentNeeds.fromGrid(grid);
      expect(needs.social, isFalse);
      expect(needs.enrichProspectsProviders.contains('social'), isFalse);
    });

    test('grille social_presence → social + website', () {
      final grid = ScoringGrid(
        id: 't',
        userId: 'u',
        name: 't',
        criteria: [
          ScoringCriterion(
            key: 'soc',
            label: 'Réseaux',
            kind: CriterionKind.component,
            maxPoints: 100,
            rule: const CriterionRule(
              type: CriterionRuleType.boolean,
              field: 'social_presence_detected',
              match: 'true',
            ),
          ),
        ],
      );
      final needs = EnrichmentNeeds.fromGrid(grid);
      expect(needs.social, isTrue);
      expect(needs.website, isTrue);
      expect(needs.enrichProspectsProviders, contains('social'));
    });

    test('détecté null si non scanné ; false si scanné sans lien', () {
      const raw = Prospect(
        id: '1',
        campaignId: 'c',
        name: 'A',
      );
      expect(
        ProspectFieldResolver.getString(raw, 'facebook_detected'),
        isNull,
      );
      expect(ProspectFieldResolver.getNumeric(raw, 'social_network_count'), isNull);

      final scanned = Prospect(
        id: '1',
        campaignId: 'c',
        name: 'A',
        socialCheckedAt: DateTime(2026, 1, 1),
      );
      expect(
        ProspectFieldResolver.getString(scanned, 'facebook_detected'),
        'false',
      );
      expect(
        ProspectFieldResolver.getString(scanned, 'social_presence_detected'),
        'false',
      );
      expect(
        ProspectFieldResolver.getNumeric(scanned, 'social_network_count'),
        0,
      );
    });
  });
}
