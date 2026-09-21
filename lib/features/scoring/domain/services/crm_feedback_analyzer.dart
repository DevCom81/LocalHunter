import '../../../../core/constants/prospect_status.dart';
import '../entities/scoring_grid.dart';
import '../entities/weight_suggestion.dart';

/// Observation CRM + scores composants pour un prospect.
class CrmFeedbackObservation {
  const CrmFeedbackObservation({
    required this.status,
    required this.componentScores,
  });

  final ProspectStatus status;
  final Map<String, int> componentScores;
}

/// Analyse déterministe : contraste cohortes positives / négatives.
/// Ne persiste rien et ne modifie jamais la grille.
class CrmFeedbackAnalyzer {
  const CrmFeedbackAnalyzer({
    this.minPerCohort = 3,
    this.minGapRatio = 0.15,
    this.maxDelta = 5,
    this.minPoints = 1,
    this.maxPointsCap = 50,
  });

  final int minPerCohort;
  final double minGapRatio;
  final int maxDelta;
  final int minPoints;
  final int maxPointsCap;

  /// Statuts « retenus / pipeline positif » (RULES §7).
  static bool isPositiveSignal(ProspectStatus s) => switch (s) {
        ProspectStatus.toStudy ||
        ProspectStatus.toContact ||
        ProspectStatus.contacted ||
        ProspectStatus.interested ||
        ProspectStatus.meeting ||
        ProspectStatus.proposal ||
        ProspectStatus.won =>
          true,
        _ => false,
      };

  /// Statuts « écartés / signal négatif ».
  static bool isNegativeSignal(ProspectStatus s) => switch (s) {
        ProspectStatus.notRelevant ||
        ProspectStatus.alreadyEquipped ||
        ProspectStatus.tooSmall ||
        ProspectStatus.franchise ||
        ProspectStatus.outOfScope ||
        ProspectStatus.lost ||
        ProspectStatus.noReply =>
          true,
        _ => false,
      };

  /// Produit des suggestions non persistées (id vide, status pending).
  List<WeightSuggestion> analyze({
    required String userId,
    required ScoringGrid grid,
    required List<CrmFeedbackObservation> observations,
  }) {
    final positive = observations.where((o) => isPositiveSignal(o.status));
    final negative = observations.where((o) => isNegativeSignal(o.status));
    final posList = positive.toList();
    final negList = negative.toList();

    if (posList.length < minPerCohort || negList.length < minPerCohort) {
      return const [];
    }

    final out = <WeightSuggestion>[];
    for (final criterion in grid.criteria) {
      if (criterion.kind != CriterionKind.component || !criterion.isActive) {
        continue;
      }
      if (criterion.maxPoints <= 0) continue;

      final posScores = _scoresFor(posList, criterion.key);
      final negScores = _scoresFor(negList, criterion.key);
      if (posScores.length < minPerCohort || negScores.length < minPerCohort) {
        continue;
      }

      final avgPos = _mean(posScores);
      final avgNeg = _mean(negScores);
      final gap = avgPos - avgNeg;
      final threshold = criterion.maxPoints * minGapRatio;
      if (gap.abs() < threshold) continue;

      final rawDelta = (gap / 2).round().clamp(-maxDelta, maxDelta);
      if (rawDelta == 0) {
        final signed = gap > 0 ? 1 : -1;
        final suggested = _clampPoints(
          criterion.maxPoints + signed,
        );
        if (suggested == criterion.maxPoints) continue;
        out.add(
          _build(
            userId: userId,
            grid: grid,
            criterion: criterion,
            suggested: suggested,
            avgPos: avgPos,
            avgNeg: avgNeg,
            gap: gap,
            posCount: posScores.length,
            negCount: negScores.length,
          ),
        );
        continue;
      }

      final suggested = _clampPoints(criterion.maxPoints + rawDelta);
      if (suggested == criterion.maxPoints) continue;

      out.add(
        _build(
          userId: userId,
          grid: grid,
          criterion: criterion,
          suggested: suggested,
          avgPos: avgPos,
          avgNeg: avgNeg,
          gap: gap,
          posCount: posScores.length,
          negCount: negScores.length,
        ),
      );
    }
    return out;
  }

  List<int> _scoresFor(List<CrmFeedbackObservation> list, String key) {
    return list
        .map((o) => o.componentScores[key])
        .whereType<int>()
        .toList();
  }

  double _mean(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  int _clampPoints(int value) => value.clamp(minPoints, maxPointsCap);

  WeightSuggestion _build({
    required String userId,
    required ScoringGrid grid,
    required ScoringCriterion criterion,
    required int suggested,
    required double avgPos,
    required double avgNeg,
    required double gap,
    required int posCount,
    required int negCount,
  }) {
    final direction = suggested > criterion.maxPoints ? 'augmenter' : 'réduire';
    final rationale =
        'Les prospects retenus ($posCount) obtiennent en moyenne '
        '${avgPos.toStringAsFixed(1)} pts sur « ${criterion.label} », '
        'contre ${avgNeg.toStringAsFixed(1)} pts pour les écartés ($negCount). '
        'Souhaitez-vous $direction ce critère de ${criterion.maxPoints} '
        'à $suggested pts ?';

    return WeightSuggestion(
      id: '',
      userId: userId,
      gridId: grid.id,
      criterionKey: criterion.key,
      criterionLabel: criterion.label,
      currentMaxPoints: criterion.maxPoints,
      suggestedMaxPoints: suggested,
      rationale: rationale,
      evidence: {
        'positive_count': posCount,
        'negative_count': negCount,
        'avg_positive': double.parse(avgPos.toStringAsFixed(2)),
        'avg_negative': double.parse(avgNeg.toStringAsFixed(2)),
        'gap': double.parse(gap.toStringAsFixed(2)),
      },
    );
  }
}
