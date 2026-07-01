import '../../domain/entities/scoring_grid.dart';
import '../../domain/repositories/scoring_grid_repository.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../grids/default_scoring_grids.dart';

class DemoScoringGridRepository implements ScoringGridRepository {
  DemoScoringGridRepository() {
    _grids = {
      DefaultScoringGrids.defaultId: DefaultScoringGrids.localHunterDefault(),
      DefaultScoringGrids.easyRestId: DefaultScoringGrids.easyRest(),
      DefaultScoringGrids.demoCampaignGridId: _demoCampaignGrid(),
    };
    _nextCustomId = 100;
  }

  late Map<String, ScoringGrid> _grids;
  int _nextCustomId = 100;

  static ScoringGrid _demoCampaignGrid() {
    return DefaultScoringGrids.duplicateFrom(
      DefaultScoringGrids.easyRest(userId: DemoData.userId),
      userId: DemoData.userId,
      name: 'Restaurants Albi — scoring',
    ).copyWith(
      id: DefaultScoringGrids.demoCampaignGridId,
      isTemplate: false,
    );
  }

  @override
  Future<List<ScoringGrid>> getAll(String userId) async {
    return _grids.values.toList();
  }

  @override
  Future<ScoringGrid?> getById(String id) async => _grids[id];

  @override
  Future<ScoringGrid> save(ScoringGrid grid) async {
    final id = grid.id.isEmpty ? 'grid-custom-${_nextCustomId++}' : grid.id;
    final saved = grid.copyWith(id: id, userId: grid.userId);
    _grids[id] = saved;
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    _grids.remove(id);
  }
}
