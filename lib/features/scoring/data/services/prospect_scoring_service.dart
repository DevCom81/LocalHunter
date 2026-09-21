import '../../../../core/constants/priority_level.dart';
import '../../../../core/constants/prospect_status.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/entities/prospect_score.dart';
import '../../domain/entities/scoring_grid.dart';
import '../engine/configurable_scoring_engine.dart';
import '../engine/score_explanation_builder.dart';
import '../grids/default_scoring_grids.dart';

/// Version persistée quand l'explicabilité (confiance + contributions) est jointe.
const scoringVersionWithExplanation = 4;

class ProspectScoringService {
  ProspectScoringService({ScoringGrid? grid}) {
    _grid = grid ?? DefaultScoringGrids.localHunterDefault();
    _engine = ConfigurableScoringEngine(grid: _grid);
  }

  late final ScoringGrid _grid;
  late final ConfigurableScoringEngine _engine;
  final _explanationBuilder = ScoreExplanationBuilder();

  Prospect applyExclusion(Prospect prospect) {
    var current = prospect;
    if (current.bodaccRadiationStatus == 'excluded' && !current.isExcluded) {
      current = current.copyWith(
        isExcluded: true,
        exclusionReason:
            current.exclusionReason ?? 'Radiation BODACC (concordante SIRENE)',
        status: ProspectStatus.excluded,
      );
    }
    final score = _engine.compute(current);
    if (score.priority != PriorityLevel.excluded) return current;
    return current.copyWith(
      isExcluded: true,
      exclusionReason: current.exclusionReason ?? 'Exclusion scoring',
      status: ProspectStatus.excluded,
    );
  }

  /// Score métier + snapshot d'explicabilité (écrasé à chaque recalcul).
  ProspectScore computeScore(Prospect prospect) {
    final score = _engine.compute(prospect);
    final explanation = _explanationBuilder.build(
      prospect: prospect,
      score: score,
      grid: _grid,
    );
    return score.copyWith(
      scoringVersion: scoringVersionWithExplanation,
      confidenceScore: explanation.confidence.score,
      filledFields: explanation.confidence.filledFields,
      totalFields: explanation.confidence.totalFields,
      missingFields: explanation.confidence.missingFields,
      explanationContributions: explanation.contributions,
      explanationWarnings: explanation.warnings,
    );
  }
}
