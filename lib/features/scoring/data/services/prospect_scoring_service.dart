import '../../../../core/constants/priority_level.dart';
import '../../../../core/constants/prospect_status.dart';
import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/entities/prospect_score.dart';
import '../../domain/entities/scoring_grid.dart';
import '../engine/configurable_scoring_engine.dart';
import '../grids/default_scoring_grids.dart';

class ProspectScoringService {
  ProspectScoringService({ScoringGrid? grid}) {
    final resolved = grid ?? DefaultScoringGrids.localHunterDefault();
    _engine = ConfigurableScoringEngine(grid: resolved);
  }

  late final ConfigurableScoringEngine _engine;

  Prospect applyExclusion(Prospect prospect) {
    final score = _engine.compute(prospect);
    if (score.priority != PriorityLevel.excluded) return prospect;
    return prospect.copyWith(
      isExcluded: true,
      exclusionReason: prospect.exclusionReason ?? 'Exclusion scoring',
      status: ProspectStatus.excluded,
    );
  }

  ProspectScore computeScore(Prospect prospect) {
    return _engine.compute(prospect);
  }
}
