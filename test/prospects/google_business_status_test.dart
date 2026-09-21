import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/scoring/data/engine/configurable_scoring_engine.dart';
import 'package:localhunter/features/scoring/data/engine/score_explanation_builder.dart';

import '../scoring/scoring_test_fixtures.dart';

void main() {
  group('B5 — Google businessStatus', () {
    test('isGoogleClosed pour CLOSED_*', () {
      expect(
        ScoringFixtures.bare()
            .copyWith(googleBusinessStatus: 'OPERATIONAL')
            .isGoogleClosed,
        isFalse,
      );
      expect(
        ScoringFixtures.bare()
            .copyWith(googleBusinessStatus: 'CLOSED_PERMANENTLY')
            .isGoogleClosed,
        isTrue,
      );
      expect(
        ScoringFixtures.bare()
            .copyWith(googleBusinessStatus: 'CLOSED_TEMPORARILY')
            .isGoogleClosed,
        isTrue,
      );
    });

    test('Google fermé sans exclusion SIRENE → avertissement, pas d\'exclusion',
        () {
      final prospect = ScoringFixtures.bare().copyWith(
        googleBusinessStatus: 'CLOSED_PERMANENTLY',
      );
      final score =
          ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
              .compute(prospect);
      final explanation = ScoreExplanationBuilder().build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );

      expect(prospect.isExcluded, isFalse);
      expect(
        explanation.warnings.any((w) => w.type == 'google_closed_sirene_open'),
        isTrue,
      );
    });
  });
}
