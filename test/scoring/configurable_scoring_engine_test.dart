import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/core/constants/priority_level.dart';
import 'package:localhunter/features/scoring/data/engine/configurable_scoring_engine.dart';
import 'package:localhunter/features/scoring/domain/entities/grid_config.dart';

import 'scoring_test_fixtures.dart';

void main() {
  group('ConfigurableScoringEngine — caractérisation', () {
    test('score borné entre 0 et 100 (grille LocalHunter Default)', () {
      final engine = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final empty = engine.compute(ScoringFixtures.bare());
      final rich = engine.compute(
        ScoringFixtures.bare(
          category: 'restaurant',
          phone: '0563000000',
          email: 'contact@example.com',
          managerName: 'Dupont',
          googleRating: 4.5,
          googleReviews: 60,
        ),
      );

      expect(empty.globalScore, inInclusiveRange(0, 100));
      expect(rich.globalScore, inInclusiveRange(0, 100));
      expect(empty.scoringVersion, 3);
    });

    test('prospect minimal sans contact : score global = 41', () {
      // accessibility 0 + website 28 (pas de site) + software 8 + commercial 5
      final engine = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final score = engine.compute(ScoringFixtures.bare());

      expect(score.componentScores['accessibility'], 0);
      expect(score.componentScores['website_opportunity'], 28);
      expect(score.componentScores['software_opportunity'], 8);
      expect(score.componentScores['commercial_health'], 5);
      expect(score.globalScore, 41);
      expect(score.priority, PriorityLevel.low);
    });

    test('prospect riche restaurant sans site : score global = 81', () {
      // access 30 + website 28 + software 18 + commercial 5 = 81
      final engine = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final score = engine.compute(
        ScoringFixtures.bare(
          category: 'restaurant',
          phone: '0563000000',
          email: 'a@b.fr',
          managerName: 'Marie',
        ),
      );

      expect(score.componentScores['accessibility'], 30);
      expect(score.componentScores['website_opportunity'], 28);
      expect(score.componentScores['software_opportunity'], 18);
      expect(score.componentScores['commercial_health'], 5);
      expect(score.globalScore, 81);
      expect(score.priority, PriorityLevel.high);
    });

    test('PageSpeed < 50 sur un site existant : opportunité site = 26', () {
      final engine = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final score = engine.compute(
        ScoringFixtures.bare(
          website: 'https://example.com',
          pagespeedScore: 42,
        ),
      );

      expect(score.componentScores['website_opportunity'], 26);
    });

    test('exclusion known_chain → score 0, priorité excluded, offre null', () {
      final engine = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final score = engine.compute(
        ScoringFixtures.bare(name: 'McDonald\'s Albi', category: 'restaurant'),
      );

      expect(score.globalScore, 0);
      expect(score.priority, PriorityLevel.excluded);
      expect(score.recommendedOffer, isNull);
      expect(score.falsePositiveRisk, 5);
      expect(
        score.componentScores.values.every((v) => v == 0),
        isTrue,
      );
    });

    test('prospect.isExcluded prime → score 0 même hors chaîne', () {
      final engine = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final score = engine.compute(
        ScoringFixtures.bare(isExcluded: true, phone: '0563000000'),
      );

      expect(score.globalScore, 0);
      expect(score.priority, PriorityLevel.excluded);
      expect(score.recommendedOffer, isNull);
    });

    test('données manquantes : règle champ téléphone → 0 pts', () {
      final engine = ConfigurableScoringEngine(
        grid: ScoringFixtures.phoneOnlyGrid(),
      );
      final score = engine.compute(ScoringFixtures.bare());

      expect(score.componentScores['has_phone'], 0);
      expect(score.globalScore, 0);
    });

    test('champ téléphone présent : normalisé à 100', () {
      final engine = ConfigurableScoringEngine(
        grid: ScoringFixtures.phoneOnlyGrid(maxPoints: 25),
      );
      final score = engine.compute(
        ScoringFixtures.bare(phone: '0563000000'),
      );

      expect(score.componentScores['has_phone'], 25);
      expect(score.globalScore, 100);
      expect(score.priority, PriorityLevel.high);
    });

    test('critère inactif : totalMax 0 → global 0, pas de points', () {
      final engine = ConfigurableScoringEngine(
        grid: ScoringFixtures.phoneOnlyGrid(active: false),
      );
      final score = engine.compute(
        ScoringFixtures.bare(phone: '0563000000'),
      );

      expect(score.componentScores.containsKey('has_phone'), isFalse);
      expect(score.globalScore, 0);
    });

    test('maxPoints à 0 : contribution nulle, pas d’explosion', () {
      final engine = ConfigurableScoringEngine(
        grid: ScoringFixtures.phoneOnlyGrid(maxPoints: 0),
      );
      final score = engine.compute(
        ScoringFixtures.bare(phone: '0563000000'),
      );

      expect(score.componentScores['has_phone'], 0);
      expect(score.globalScore, 0);
    });

    test('sans règles de recommandation : offre = offerLabel', () {
      final engine = ConfigurableScoringEngine(
        grid: ScoringFixtures.phoneOnlyGrid(offerLabel: 'Pose de parquet'),
      );
      final score = engine.compute(
        ScoringFixtures.bare(phone: '0563000000'),
      );

      expect(score.recommendedOffer, 'Pose de parquet');
    });

    test('avec règles : offre seulement si seuil d’étoiles atteint', () {
      final grid = ScoringFixtures.localHunter().copyWith(
        offerLabel: 'Site web',
        recommendationConfig: const GridRecommendationConfig(
          rules: [
            RecommendationRule(criterionKey: 'site_score', minStars: 3),
          ],
        ),
      );
      final engine = ConfigurableScoringEngine(grid: grid);

      // Pas de site → site_score élevé (≥ 3) → offre recommandée
      final noSite = engine.compute(ScoringFixtures.bare());
      expect(noSite.subScores['site_score']!, greaterThanOrEqualTo(3));
      expect(noSite.recommendedOffer, 'Site web');

      // Site HTTPS mature → site_score bas (< 3) → pas d’offre
      final mature = engine.compute(
        ScoringFixtures.bare(website: 'https://boutique-locale.fr'),
      );
      expect(mature.subScores['site_score']!, lessThan(3));
      expect(mature.recommendedOffer, isNull);
    });

    test('reproductibilité : mêmes entrées → mêmes scores métier', () {
      final engine = ConfigurableScoringEngine(grid: ScoringFixtures.localHunter());
      final prospect = ScoringFixtures.bare(
        category: 'coiffeur',
        phone: '0563111111',
        website: 'http://salon.fr',
        googleRating: 3.8,
        googleReviews: 12,
      );

      final a = engine.compute(prospect);
      final b = engine.compute(prospect);

      expect(a.globalScore, b.globalScore);
      expect(a.componentScores, b.componentScores);
      expect(a.subScores, b.subScores);
      expect(a.priority, b.priority);
      expect(a.recommendedOffer, b.recommendedOffer);
      expect(a.scoringVersion, b.scoringVersion);
    });

    test('seuils de priorité inchangés (≥70 high, ≥45 medium)', () {
      expect(PriorityLevel.fromScore(70, isExcluded: false), PriorityLevel.high);
      expect(PriorityLevel.fromScore(69, isExcluded: false), PriorityLevel.medium);
      expect(PriorityLevel.fromScore(45, isExcluded: false), PriorityLevel.medium);
      expect(PriorityLevel.fromScore(44, isExcluded: false), PriorityLevel.low);
      expect(PriorityLevel.fromScore(99, isExcluded: true), PriorityLevel.excluded);
    });
  });
}
