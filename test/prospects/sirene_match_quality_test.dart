import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/prospects/data/services/prospect_enrichment_service.dart';
import 'package:localhunter/features/scoring/data/engine/configurable_scoring_engine.dart';
import 'package:localhunter/features/scoring/data/engine/score_explanation_builder.dart';

import '../scoring/scoring_test_fixtures.dart';

void main() {
  group('B3 — qualité matching SIRENE', () {
    test('fromJson lit match_score et match_ambiguous', () {
      final e = ProspectEnrichment.fromJson({
        'siren': '123456789',
        'siret': '12345678900012',
        'naf_code': '56.10A',
        'legal_form': '5499',
        'creation_date': '2010-01-01',
        'active': true,
        'match_score': 88,
        'match_ambiguous': true,
        'pagespeed_score': null,
      });
      expect(e.matchScore, 88);
      expect(e.matchAmbiguous, isTrue);

      final applied = e.applyTo(ScoringFixtures.bare());
      expect(applied.sireneMatchScore, 88);
      expect(applied.sireneMatchAmbiguous, isTrue);
      expect(applied.siret, '12345678900012');
    });

    test('ambiguïté : avertissement + pénalité confiance −10', () {
      final prospect = ScoringFixtures.bare(phone: '0563').copyWith(
        siren: '123456789',
        siret: '12345678900012',
        sireneMatchScore: 82,
        sireneMatchAmbiguous: true,
      );
      final score = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
          .compute(prospect);
      final explanation = ScoreExplanationBuilder().build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );

      expect(
        explanation.warnings.any((w) => w.type == 'sirene_ambiguous'),
        isTrue,
      );
      // phone + siret → 2/8 * 50 ≈ 13 ; +30 SIRENE ; −10 ambigu = 33
      expect(explanation.confidence.score, 33);
    });

    test('match < 70 : avertissement sirene_low_match', () {
      final prospect = ScoringFixtures.bare().copyWith(
        siren: '123456789',
        siret: '12345678900012',
        sireneMatchScore: 55,
        sireneMatchAmbiguous: false,
      );
      final score = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
          .compute(prospect);
      final explanation = ScoreExplanationBuilder().build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );

      expect(
        explanation.warnings.any((w) => w.type == 'sirene_low_match'),
        isTrue,
      );
    });
  });
}
