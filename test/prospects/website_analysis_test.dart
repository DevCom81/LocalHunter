import 'package:flutter_test/flutter_test.dart';
import 'package:localhunter/features/prospects/data/services/prospect_enrichment_service.dart';
import 'package:localhunter/features/prospects/domain/entities/prospect.dart';
import 'package:localhunter/features/scoring/data/engine/configurable_scoring_engine.dart';
import 'package:localhunter/features/scoring/data/engine/score_explanation_builder.dart';

import '../scoring/scoring_test_fixtures.dart';

void main() {
  group('C3 — analyse site légère', () {
    test('ProspectEnrichment mappe les champs website_*', () {
      final e = ProspectEnrichment.fromJson({
        'website_reachable': true,
        'website_https': true,
        'website_http_status': 200,
        'website_title': 'Boulangerie Dupont',
        'website_has_viewport': false,
        'pagespeed_score': 42,
      });

      expect(e.websiteReachable, isTrue);
      expect(e.websiteHttps, isTrue);
      expect(e.websiteHttpStatus, 200);
      expect(e.websiteTitle, 'Boulangerie Dupont');
      expect(e.websiteHasViewport, isFalse);
      expect(e.pagespeedScore, 42);

      final applied = e.applyTo(
        const Prospect(
          id: 'p1',
          campaignId: 'c1',
          name: 'Test',
          website: 'https://example.com',
        ),
      );
      expect(applied.websiteReachable, isTrue);
      expect(applied.websiteTitle, 'Boulangerie Dupont');
      expect(applied.pagespeedScore, 42);
    });

    test('site injoignable → avertissement website_unreachable', () {
      const prospect = Prospect(
        id: 'p1',
        campaignId: 'c1',
        name: 'Test',
        website: 'https://down.example',
        websiteReachable: false,
      );
      final score =
          ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
              .compute(prospect);
      final explanation = ScoreExplanationBuilder().build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );
      expect(
        explanation.warnings.any((w) => w.type == 'website_unreachable'),
        isTrue,
      );
    });

    test('viewport absent → info website_no_viewport', () {
      const prospect = Prospect(
        id: 'p1',
        campaignId: 'c1',
        name: 'Test',
        website: 'https://ok.example',
        websiteReachable: true,
        websiteHasViewport: false,
      );
      final score =
          ConfigurableScoringEngine(grid: ScoringFixtures.localHunter())
              .compute(prospect);
      final explanation = ScoreExplanationBuilder().build(
        prospect: prospect,
        score: score,
        grid: ScoringFixtures.localHunter(),
      );
      expect(
        explanation.warnings.any((w) => w.type == 'website_no_viewport'),
        isTrue,
      );
    });
  });
}
