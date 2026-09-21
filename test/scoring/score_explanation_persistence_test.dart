import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/prospects/data/models/prospect_score_dto.dart';
import 'package:localhunter/features/scoring/data/services/prospect_scoring_service.dart';
import 'package:localhunter/features/scoring/domain/entities/score_explanation.dart';

import 'scoring_test_fixtures.dart';

void main() {
  group('B1 — persistance explicabilité', () {
    test('computeScore joint confiance + contributions (version 4)', () {
      final service = ProspectScoringService(grid: ScoringFixtures.localHunter());
      final score = service.computeScore(ScoringFixtures.bare(phone: '0563'));

      expect(score.scoringVersion, scoringVersionWithExplanation);
      expect(score.confidenceScore, isNotNull);
      expect(score.filledFields, isNotNull);
      expect(score.totalFields, 8);
      expect(score.explanationContributions, isNotEmpty);
      expect(score.explanationWarnings, isNotEmpty); // sirene_unmatched
    });

    test('DTO round-trip conserve le snapshot', () {
      final service = ProspectScoringService(grid: ScoringFixtures.localHunter());
      final score = service.computeScore(
        ScoringFixtures.bare().copyWith(siren: '123456789', siret: '12345678900012'),
      );
      final json = prospectScoreToDto(score).toInsertJson();
      final restored = prospectScoreFromDto(ProspectScoreDto.fromJson(json));

      expect(restored.confidenceScore, score.confidenceScore);
      expect(restored.filledFields, score.filledFields);
      expect(restored.missingFields, score.missingFields);
      expect(restored.explanationContributions.length,
          score.explanationContributions.length);
      expect(restored.explanationWarnings.first.type,
          score.explanationWarnings.first.type);
      expect(json['contributions'], isA<List>());
      expect(json['score_warnings'], isA<List>());
    });

    test('fromPersisted null si score pré-B1 (confidence absente)', () {
      final engineScore = ScoringFixtures.localHunter();
      final raw = ProspectScoringService(grid: engineScore)
          .computeScore(ScoringFixtures.bare())
          .copyWith(); // still has confidence

      // Simule un score lu sans colonnes B1
      final preB1 = prospectScoreFromDto(
        ProspectScoreDto.fromJson({
          ...prospectScoreToDto(raw).toInsertJson()
            ..remove('confidence_score')
            ..remove('filled_fields')
            ..remove('total_fields')
            ..['confidence_score'] = null
            ..['filled_fields'] = null
            ..['total_fields'] = null
            ..['contributions'] = []
            ..['score_warnings'] = []
            ..['missing_fields'] = [],
        }),
      );

      expect(
        ScoreExplanation.fromPersisted(
          globalScore: preB1.globalScore,
          confidenceScore: preB1.confidenceScore,
          filledFields: preB1.filledFields,
          totalFields: preB1.totalFields,
          missingFields: preB1.missingFields,
          contributions: preB1.explanationContributions,
          warnings: preB1.explanationWarnings,
        ),
        isNull,
      );
    });

    test('fromPersisted reconstruit l\'explication sauvegardée', () {
      final score = ProspectScoringService(grid: ScoringFixtures.localHunter())
          .computeScore(ScoringFixtures.bare(phone: '0563'));
      final explanation = ScoreExplanation.fromPersisted(
        globalScore: score.globalScore,
        confidenceScore: score.confidenceScore,
        filledFields: score.filledFields,
        totalFields: score.totalFields,
        missingFields: score.missingFields,
        contributions: score.explanationContributions,
        warnings: score.explanationWarnings,
      );

      expect(explanation, isNotNull);
      expect(explanation!.confidence.score, score.confidenceScore);
      expect(explanation.contributions.length,
          score.explanationContributions.length);
    });
  });
}
