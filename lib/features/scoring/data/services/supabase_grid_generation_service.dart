import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/services/scoring_grid_generator.dart';
import 'generated_grid_parser.dart';

/// Appelle l'Edge Function `generate-scoring-grid` (OpenRouter + cache
/// partagé côté serveur) et parse la grille retournée.
class SupabaseGridGenerationService {
  SupabaseGridGenerationService(this._client);

  final SupabaseClient _client;

  Future<GeneratedGridResult> generate({
    required String business,
    required String userId,
    String productsServices = '',
  }) async {
    final response = await _client.functions.invoke(
      'generate-scoring-grid',
      body: {
        'business': business,
        if (productsServices.isNotEmpty) 'productsServices': productsServices,
      },
    );

    if (response.status != 200) {
      final err = response.data is Map ? response.data['error'] : response.data;
      throw Exception(err ?? 'Erreur generate-scoring-grid (${response.status})');
    }

    final data = response.data as Map<String, dynamic>;
    final gridJson = data['grid'] as Map<String, dynamic>?;
    if (gridJson == null) {
      throw Exception('Réponse invalide : grille absente');
    }

    return GeneratedGridResult(
      grid: parseGeneratedGrid(gridJson, userId: userId),
      source: data['fromCache'] == true
          ? GridGenerationSource.cache
          : GridGenerationSource.ai,
    );
  }
}
