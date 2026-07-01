import '../entities/scoring_grid.dart';

abstract class ScoringGridRepository {
  Future<List<ScoringGrid>> getAll(String userId);
  Future<ScoringGrid?> getById(String id);
  Future<ScoringGrid> save(ScoringGrid grid);
  Future<void> delete(String id);
}
