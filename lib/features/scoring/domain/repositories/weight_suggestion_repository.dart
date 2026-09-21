import '../entities/weight_suggestion.dart';

abstract class WeightSuggestionRepository {
  Future<List<WeightSuggestion>> listPending(String gridId);

  /// Remplace toutes les suggestions `pending` de la grille.
  Future<List<WeightSuggestion>> replacePending(
    String gridId,
    List<WeightSuggestion> suggestions,
  );

  Future<WeightSuggestion> markStatus(
    String id,
    WeightSuggestionStatus status,
  );
}
