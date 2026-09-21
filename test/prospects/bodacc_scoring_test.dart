import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/core/constants/priority_level.dart';
import 'package:localhunter/features/prospects/domain/entities/prospect.dart';
import 'package:localhunter/features/scoring/data/engine/configurable_scoring_engine.dart';
import 'package:localhunter/features/scoring/data/engine/prospect_field_resolver.dart';
import 'package:localhunter/features/scoring/data/engine/score_explanation_builder.dart';
import 'package:localhunter/features/scoring/data/services/prospect_scoring_service.dart';
import 'package:localhunter/features/scoring/domain/entities/scoring_grid.dart';

import '../scoring/scoring_test_fixtures.dart';

void main() {
  group('C4.3 — critères BODACC poids 0', () {
    test('grille défaut : totalMax inchangé (100) malgré critères BODACC', () {
      final grid = ScoringFixtures.localHunter();
      expect(grid.totalMax, 100);
      expect(
        grid.criteria.any((c) => c.key.startsWith('bodacc_')),
        isTrue,
      );
      expect(
        grid.criteria
            .where((c) => c.key.startsWith('bodacc_'))
            .every((c) => c.maxPoints == 0),
        isTrue,
      );
    });

    test('poids 0 : score identique avec ou sans signaux BODACC', () {
      final engine =
          ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final bare = engine.compute(ScoringFixtures.bare());
      final withSignals = engine.compute(
        ScoringFixtures.bare().copyWith(
          bodaccFetchedAt: DateTime(2026, 1, 1),
          bodaccNoResults: false,
          bodaccHasAccountsFiling: true,
          bodaccHasManagerChange: true,
          bodaccHasCollectiveProceeding: true,
        ),
      );
      expect(withSignals.globalScore, bare.globalScore);
      expect(bare.globalScore, 41);
    });

    test('critère BODACC activé (maxPoints>0) augmente le score si flag true',
        () {
      final base = ScoringFixtures.localHunter();
      final criteria = base.criteria.map((c) {
        if (c.key == 'bodacc_accounts_filing') {
          return c.copyWith(maxPoints: 10);
        }
        return c;
      }).toList();
      // totalMax devient 110
      final grid = base.copyWith(criteria: criteria);
      final engine = ConfigurableScoringEngine(grid: grid);

      final without = engine.compute(
        const Prospect(
          id: 'p1',
          campaignId: 'c1',
          name: 'Test',
          bodaccFetchedAt: null,
        ),
      );
      final withFlag = engine.compute(
        Prospect(
          id: 'p1',
          campaignId: 'c1',
          name: 'Test',
          bodaccFetchedAt: DateTime(2026, 1, 1),
          bodaccNoResults: false,
          bodaccHasAccountsFiling: true,
        ),
      );
      expect(withFlag.globalScore, greaterThan(without.globalScore));
      expect(withFlag.componentScores['bodacc_accounts_filing'], 10);
    });

    test('absence BODACC / no_results → champ null (pas de faux positif)', () {
      expect(
        ProspectFieldResolver.getString(
          const Prospect(id: 'p', campaignId: 'c', name: 'n'),
          'bodacc_has_collective_proceeding',
        ),
        isNull,
      );
      expect(
        ProspectFieldResolver.getString(
          Prospect(
            id: 'p',
            campaignId: 'c',
            name: 'n',
            bodaccFetchedAt: DateTime(2026, 1, 1),
            bodaccNoResults: true,
            bodaccHasCollectiveProceeding: false,
          ),
          'bodacc_has_collective_proceeding',
        ),
        isNull,
      );
    });
  });

  group('C4.3 — radiation & warnings', () {
    test('radiation excluded → priority excluded, score 0', () {
      final engine =
          ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final score = engine.compute(
        ScoringFixtures.bare().copyWith(
          bodaccRadiationStatus: 'excluded',
          bodaccHasRadiation: true,
          bodaccFetchedAt: DateTime(2026, 1, 1),
          bodaccNoResults: false,
        ),
      );
      expect(score.globalScore, 0);
      expect(score.priority, PriorityLevel.excluded);
    });

    test('radiation review → pas d\'exclusion auto, warning', () {
      final prospect = ScoringFixtures.bare().copyWith(
        bodaccRadiationStatus: 'review',
        bodaccHasRadiation: true,
        bodaccFetchedAt: DateTime(2026, 1, 1),
        bodaccNoResults: false,
      );
      final score =
          ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
              .compute(prospect);
      expect(score.priority, isNot(PriorityLevel.excluded));
      final explanation = ScoreExplanationBuilder().build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );
      expect(
        explanation.warnings.any((w) => w.type == 'bodacc_radiation_review'),
        isTrue,
      );
    });

    test('procédure collective → warning critique, pas d\'exclusion', () {
      final prospect = ScoringFixtures.bare().copyWith(
        bodaccHasCollectiveProceeding: true,
        bodaccFetchedAt: DateTime(2026, 1, 1),
        bodaccNoResults: false,
      );
      final service =
          ProspectScoringService(grid: ScoringFixtures.localHunter());
      final applied = service.applyExclusion(prospect);
      expect(applied.isExcluded, isFalse);
      final score = service.computeScore(prospect);
      expect(
        score.explanationWarnings
            .any((w) => w.type == 'bodacc_collective_proceeding'),
        isTrue,
      );
    });

    test('applyExclusion persiste le motif radiation', () {
      final service =
          ProspectScoringService(grid: ScoringFixtures.localHunter());
      final applied = service.applyExclusion(
        ScoringFixtures.bare().copyWith(
          bodaccRadiationStatus: 'excluded',
          bodaccFetchedAt: DateTime(2026, 1, 1),
          bodaccNoResults: false,
        ),
      );
      expect(applied.isExcluded, isTrue);
      expect(applied.exclusionReason, contains('Radiation BODACC'));
    });
  });
}
