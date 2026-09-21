import 'package:flutter_test/flutter_test.dart';

import 'package:localhunter/core/constants/prospect_status.dart';
import 'package:localhunter/features/scoring/domain/entities/scoring_grid.dart';
import 'package:localhunter/features/scoring/domain/services/crm_feedback_analyzer.dart';

ScoringGrid _grid({required int maxPoints}) {
  return ScoringGrid(
    id: 'grid-1',
    userId: 'user-1',
    name: 'Test',
    criteria: [
      ScoringCriterion(
        key: 'website',
        label: 'Site web',
        kind: CriterionKind.component,
        maxPoints: maxPoints,
      ),
      ScoringCriterion(
        key: 'phone',
        label: 'Téléphone',
        kind: CriterionKind.component,
        maxPoints: 10,
      ),
    ],
  );
}

CrmFeedbackObservation _obs(ProspectStatus status, int website, int phone) {
  return CrmFeedbackObservation(
    status: status,
    componentScores: {'website': website, 'phone': phone},
  );
}

void main() {
  const analyzer = CrmFeedbackAnalyzer();

  test('retourne vide si cohortes trop petites', () {
    final observations = [
      _obs(ProspectStatus.won, 20, 5),
      _obs(ProspectStatus.won, 18, 5),
      _obs(ProspectStatus.notRelevant, 2, 5),
      _obs(ProspectStatus.notRelevant, 1, 5),
    ];
    final result = analyzer.analyze(
      userId: 'user-1',
      grid: _grid(maxPoints: 20),
      observations: observations,
    );
    expect(result, isEmpty);
  });

  test('suggère d\'augmenter un critère discriminant positif', () {
    final observations = [
      for (var i = 0; i < 3; i++) _obs(ProspectStatus.toContact, 18, 5),
      for (var i = 0; i < 3; i++) _obs(ProspectStatus.tooSmall, 2, 5),
    ];
    final result = analyzer.analyze(
      userId: 'user-1',
      grid: _grid(maxPoints: 20),
      observations: observations,
    );
    expect(result, isNotEmpty);
    final website = result.singleWhere((s) => s.criterionKey == 'website');
    expect(website.suggestedMaxPoints, greaterThan(website.currentMaxPoints));
    expect(website.suggestedMaxPoints, lessThanOrEqualTo(50));
    expect(result.where((s) => s.criterionKey == 'phone'), isEmpty);
  });

  test('suggère de réduire un critère qui favorise les écartés', () {
    final observations = [
      for (var i = 0; i < 3; i++) _obs(ProspectStatus.won, 2, 5),
      for (var i = 0; i < 3; i++) _obs(ProspectStatus.notRelevant, 18, 5),
    ];
    final result = analyzer.analyze(
      userId: 'user-1',
      grid: _grid(maxPoints: 20),
      observations: observations,
    );
    final website = result.singleWhere((s) => s.criterionKey == 'website');
    expect(website.suggestedMaxPoints, lessThan(website.currentMaxPoints));
    expect(website.suggestedMaxPoints, greaterThanOrEqualTo(1));
  });

  test('ignore newProspect et excluded', () {
    expect(CrmFeedbackAnalyzer.isPositiveSignal(ProspectStatus.newProspect), isFalse);
    expect(CrmFeedbackAnalyzer.isNegativeSignal(ProspectStatus.excluded), isFalse);
  });
}
