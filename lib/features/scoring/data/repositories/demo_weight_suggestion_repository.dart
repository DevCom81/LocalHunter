import 'package:uuid/uuid.dart';

import '../../domain/entities/weight_suggestion.dart';
import '../../domain/repositories/weight_suggestion_repository.dart';

class DemoWeightSuggestionRepository implements WeightSuggestionRepository {
  final _items = <WeightSuggestion>[];
  final _uuid = const Uuid();

  @override
  Future<List<WeightSuggestion>> listPending(String gridId) async {
    return _items
        .where((s) => s.gridId == gridId && s.isPending)
        .toList();
  }

  @override
  Future<List<WeightSuggestion>> replacePending(
    String gridId,
    List<WeightSuggestion> suggestions,
  ) async {
    _items.removeWhere((s) => s.gridId == gridId && s.isPending);
    final created = suggestions
        .map(
          (s) => WeightSuggestion(
            id: _uuid.v4(),
            userId: s.userId,
            gridId: s.gridId,
            criterionKey: s.criterionKey,
            criterionLabel: s.criterionLabel,
            currentMaxPoints: s.currentMaxPoints,
            suggestedMaxPoints: s.suggestedMaxPoints,
            rationale: s.rationale,
            evidence: s.evidence,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
    _items.addAll(created);
    return created;
  }

  @override
  Future<WeightSuggestion> markStatus(
    String id,
    WeightSuggestionStatus status,
  ) async {
    final i = _items.indexWhere((s) => s.id == id);
    if (i < 0) {
      throw StateError('Suggestion introuvable: $id');
    }
    final updated = _items[i].copyWith(
      status: status,
      resolvedAt: DateTime.now(),
    );
    _items[i] = updated;
    return updated;
  }
}
