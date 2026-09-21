import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/scoring/data/engine/configurable_scoring_engine.dart';
import 'package:localhunter/features/scoring/data/engine/score_explanation_builder.dart';
import 'package:localhunter/features/scoring/domain/entities/score_confidence.dart';

import 'scoring_test_fixtures.dart';

void main() {
  final builder = ScoreExplanationBuilder();

  group('ScoreExplanationBuilder — confiance', () {
    test('prospect vide : complétude 0, pas de SIRENE, confiance basse', () {
      final prospect = ScoringFixtures.bare();
      final score = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
          .compute(prospect);
      final explanation = builder.build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );

      expect(explanation.confidence.filledFields, 0);
      expect(explanation.confidence.totalFields, 8);
      expect(explanation.confidence.score, 0);
      expect(explanation.confidence.missingFields, hasLength(8));
      expect(
        explanation.confidence.missingFieldLabels,
        containsAll(['Adresse', 'Téléphone', 'SIRET']),
      );
      expect(
        explanation.warnings.any((w) => w.type == 'sirene_unmatched'),
        isTrue,
      );
    });

    test('SIRENE + finances + champs : confiance élevée', () {
      final prospect = ScoringFixtures.bare(
        phone: '0563000000',
        website: 'https://example.fr',
      ).copyWith(
        siret: '12345678900012',
        siren: '123456789',
        managerName: 'Dupont',
        annualRevenue: 250000,
        pagespeedScore: 55,
        creationDate: DateTime(2015, 1, 1),
      );
      // address manquante → 7/8
      final score = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
          .compute(prospect);
      final explanation = builder.build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );

      // complétude 7/8 * 50 ≈ 44 ; +30 SIRENE ; +20 finances = 94
      expect(explanation.confidence.filledFields, 7);
      expect(explanation.confidence.score, 94);
      expect(explanation.confidence.missingFields, ['address']);
      expect(explanation.confidence.missingFieldLabels, ['Adresse']);
      expect(explanation.warnings, isEmpty);
    });

    test('fermé SIRENE listé : pénalité −25 + avertissement critique', () {
      final prospect = ScoringFixtures.bare(isExcluded: true).copyWith(
        siret: '12345678900012',
        siren: '123456789',
        exclusionReason: 'Établissement fermé (SIRENE)',
      );
      final score = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
          .compute(prospect);
      final explanation = builder.build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );

      // siret rempli → 1/8 * 50 ≈ 6 ; +30 SIRENE ; −25 contradiction = 11
      expect(explanation.confidence.filledFields, 1);
      expect(explanation.confidence.score, 11);
      expect(
        explanation.warnings.any((w) => w.type == 'sirene_closed_listed'),
        isTrue,
      );
      expect(
        explanation.warnings
            .firstWhere((w) => w.type == 'sirene_closed_listed')
            .severity,
        ScoreWarningSeverity.critical,
      );
    });

    test('SIREN sans CA : avertissement finances_missing', () {
      final prospect = ScoringFixtures.bare().copyWith(siren: '123456789');
      final score = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
          .compute(prospect);
      final explanation = builder.build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );

      expect(
        explanation.warnings.any((w) => w.type == 'finances_missing'),
        isTrue,
      );
      // 0 + 30 SIRENE, pas de +20 finances
      expect(explanation.confidence.score, 30);
    });
  });

  group('ScoreExplanationBuilder — contributions', () {
    test('somme des contributions ≈ score global (grille 100 pts)', () {
      final grid = ScoringFixtures.localHunter();
      final prospect = ScoringFixtures.bare(
        category: 'restaurant',
        phone: '0563000000',
        email: 'a@b.fr',
        managerName: 'Marie',
      );
      final score = ConfigurableScoringEngine(grid: grid).compute(prospect);
      final explanation = builder.build(
        prospect: prospect,
        score: score,
        grid: grid,
      );

      expect(explanation.globalScore, score.globalScore);
      expect(explanation.contributions, hasLength(4));
      final sum =
          explanation.contributions.fold<int>(0, (a, c) => a + c.contribution);
      // Arrondis par critère : tolérance ±1
      expect((sum - score.globalScore).abs(), lessThanOrEqualTo(1));
    });

    test('critère à 0 pts → isPositive false, clé *_zero', () {
      final grid = ScoringFixtures.localHunter();
      final score = ConfigurableScoringEngine(grid: grid).compute(
        ScoringFixtures.bare(),
      );
      final explanation = builder.build(
        prospect: ScoringFixtures.bare(),
        score: score,
        grid: grid,
      );

      final access = explanation.contributions
          .firstWhere((c) => c.criterionKey == 'accessibility');
      expect(access.value, 0);
      expect(access.isPositive, isFalse);
      expect(access.explanationKey, 'accessibility_zero');
      expect(
        access.explanation,
        'Décisionnaire difficile à joindre (pas de téléphone, e-mail ou nom).',
      );
      expect(access.sourceLabel, 'Scorer intégré');
    });

    test('libellé FR connu pour opportunité site maximale', () {
      final grid = ScoringFixtures.localHunter();
      final prospect = ScoringFixtures.bare(); // pas de site → 28 pts
      final score = ConfigurableScoringEngine(grid: grid).compute(prospect);
      final explanation = builder.build(
        prospect: prospect,
        score: score,
        grid: grid,
      );

      final site = explanation.contributions
          .firstWhere((c) => c.criterionKey == 'website_opportunity');
      expect(site.explanationKey, 'website_opportunity_partial');
      expect(site.explanation, contains('Opportunité site significative'));
      expect(site.sourceLabel, 'PageSpeed / site web');
    });

    test('critère custom : fallback FR générique', () {
      final grid = ScoringFixtures.phoneOnlyGrid();
      final score = ConfigurableScoringEngine(grid: grid).compute(
        ScoringFixtures.bare(phone: '0563000000'),
      );
      final explanation = builder.build(
        prospect: ScoringFixtures.bare(phone: '0563000000'),
        score: score,
        grid: grid,
      );

      final phone = explanation.contributions.single;
      expect(phone.explanationKey, 'has_phone_max');
      expect(phone.explanation, contains('score maximal'));
      expect(phone.sourceLabel, 'Champ prospect');
    });

    test('indépendant du score métier : confiance ≠ globalScore', () {
      final grid = ScoringFixtures.localHunter();
      // Score métier élevé (pas de site) mais confiance nulle (pas de données)
      final prospect = ScoringFixtures.bare();
      final score = ConfigurableScoringEngine(grid: grid).compute(prospect);
      final explanation = builder.build(
        prospect: prospect,
        score: score,
        grid: grid,
      );

      expect(explanation.globalScore, greaterThan(0));
      expect(explanation.confidence.score, 0);
    });
  });
}
