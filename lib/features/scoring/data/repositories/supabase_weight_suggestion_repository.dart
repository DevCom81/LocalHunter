import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/weight_suggestion.dart';
import '../../domain/repositories/weight_suggestion_repository.dart';
import '../models/weight_suggestion_dto.dart';

class SupabaseWeightSuggestionRepository
    implements WeightSuggestionRepository {
  SupabaseWeightSuggestionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WeightSuggestion>> listPending(String gridId) async {
    final rows = await _client
        .from('scoring_weight_suggestions')
        .select()
        .eq('grid_id', gridId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List)
        .map(
          (r) => suggestionFromDto(
            WeightSuggestionDto.fromJson(Map<String, dynamic>.from(r as Map)),
          ),
        )
        .toList();
  }

  @override
  Future<List<WeightSuggestion>> replacePending(
    String gridId,
    List<WeightSuggestion> suggestions,
  ) async {
    await _client
        .from('scoring_weight_suggestions')
        .delete()
        .eq('grid_id', gridId)
        .eq('status', 'pending');

    if (suggestions.isEmpty) return const [];

    final payload = suggestions.map((s) => suggestionToDto(s).toInsertJson()).toList();
    final rows = await _client
        .from('scoring_weight_suggestions')
        .insert(payload)
        .select();
    return (rows as List)
        .map(
          (r) => suggestionFromDto(
            WeightSuggestionDto.fromJson(Map<String, dynamic>.from(r as Map)),
          ),
        )
        .toList();
  }

  @override
  Future<WeightSuggestion> markStatus(
    String id,
    WeightSuggestionStatus status,
  ) async {
    final row = await _client
        .from('scoring_weight_suggestions')
        .update({
          'status': status.name,
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return suggestionFromDto(
      WeightSuggestionDto.fromJson(Map<String, dynamic>.from(row)),
    );
  }
}
