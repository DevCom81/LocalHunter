import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/prospecting_profile.dart';
import '../../domain/services/scoring_grid_generator.dart';
import 'generated_grid_parser.dart';

/// Appelle l'Edge Function `generate-scoring-grid` (profil Phase 5 + grille).
class SupabaseGridGenerationService {
  SupabaseGridGenerationService(this._client);

  final SupabaseClient _client;

  Future<ProspectingProfile> proposeProfile({
    required String business,
    String productsServices = '',
  }) async {
    final response = await _client.functions.invoke(
      'generate-scoring-grid',
      body: {
        'step': 'profile',
        'business': business,
        if (productsServices.isNotEmpty) 'productsServices': productsServices,
      },
    );

    if (response.status != 200) {
      final err = response.data is Map ? response.data['error'] : response.data;
      throw Exception(err ?? 'Erreur profil IA (${response.status})');
    }

    final data = response.data as Map<String, dynamic>;
    final profileJson = data['profile'] as Map<String, dynamic>?;
    if (profileJson == null) {
      throw Exception('Réponse invalide : profil absent');
    }
    return ProspectingProfile.fromJson(profileJson);
  }

  Future<GeneratedGridResult> generate({
    required String business,
    required String userId,
    String productsServices = '',
    Map<String, dynamic>? commercialProfile,
    ProspectingProfile? prospectingProfile,
  }) async {
    final body = <String, dynamic>{
      'step': 'grid',
      'business': business,
    };
    if (productsServices.isNotEmpty) {
      body['productsServices'] = productsServices;
    }
    if (commercialProfile != null) {
      body['commercialProfile'] = commercialProfile;
    }
    if (prospectingProfile != null) {
      body['prospectingProfile'] = prospectingProfile.toJson();
    }

    final response = await _client.functions.invoke(
      'generate-scoring-grid',
      body: body,
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
