import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/scoring_grid.dart';
import '../../domain/repositories/scoring_grid_repository.dart';
import '../models/scoring_grid_dto.dart';

class SupabaseScoringGridRepository implements ScoringGridRepository {
  SupabaseScoringGridRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  static const _gridSelect = '*, scoring_criteria(*)';

  @override
  Future<List<ScoringGrid>> getAll(String userId) async {
    return _fetchGrids();
  }

  @override
  Future<ScoringGrid?> getById(String id) async {
    // Ids sentinelles du mode démo ('grid-easyrest'…) : jamais en base,
    // et un non-UUID ferait échouer la requête sur la colonne UUID.
    if (!_looksLikeUuid(id)) return null;
    final row = await _client
        .from('scoring_grids')
        .select(_gridSelect)
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (row == null) return null;
    return scoringGridFromDto(ScoringGridDto.fromJson(row));
  }

  @override
  Future<ScoringGrid> save(ScoringGrid grid) async {
    final gridId = await _persistGrid(grid);
    final saved = grid.copyWith(id: gridId);
    await _syncCriteria(saved);
    return (await getById(gridId)) ?? saved;
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('scoring_grids').delete().eq('id', id).eq('user_id', _userId);
  }

  Future<void> _syncCriteria(ScoringGrid grid) async {
    final payload = criteriaToUpsert(grid);
    if (payload.isNotEmpty) {
      await _client.from('scoring_criteria').upsert(
            payload,
            onConflict: 'grid_id,criterion_key',
          );
    }
    final keys = grid.criteria.map((c) => c.key).toSet();
    final existing = await _client
        .from('scoring_criteria')
        .select('criterion_key')
        .eq('grid_id', grid.id);
    for (final row in existing as List) {
      final key = row['criterion_key'] as String;
      if (!keys.contains(key)) {
        await _client
            .from('scoring_criteria')
            .delete()
            .eq('grid_id', grid.id)
            .eq('criterion_key', key);
      }
    }
  }

  Future<List<ScoringGrid>> _fetchGrids() async {
    final rows = await _client
        .from('scoring_grids')
        .select(_gridSelect)
        .eq('user_id', _userId)
        .order('created_at');
    return (rows as List)
        .map((r) => scoringGridFromDto(ScoringGridDto.fromJson(r)))
        .toList();
  }

  Future<String> _persistGrid(ScoringGrid grid) async {
    final isNew = !_looksLikeUuid(grid.id);
    if (isNew) {
      final row = await _client
          .from('scoring_grids')
          .insert({
            'user_id': _userId,
            'name': grid.name,
            'description': grid.description,
            'offer_label': grid.offerLabel,
            'is_template': grid.isTemplate,
            'exclusion_config': grid.exclusionConfig.toJson(),
            'recommendation_config': grid.recommendationConfig.toJson(),
          })
          .select('id')
          .single();
      return row['id'] as String;
    }
    await _client.from('scoring_grids').update({
      'name': grid.name,
      'description': grid.description,
      'offer_label': grid.offerLabel,
      'is_template': grid.isTemplate,
      'exclusion_config': grid.exclusionConfig.toJson(),
      'recommendation_config': grid.recommendationConfig.toJson(),
    }).eq('id', grid.id).eq('user_id', _userId);
    return grid.id;
  }

  bool _looksLikeUuid(String id) {
    final re = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return re.hasMatch(id);
  }
}
