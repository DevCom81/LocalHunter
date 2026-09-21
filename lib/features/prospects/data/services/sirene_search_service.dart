import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/prospect_status.dart';
import '../../domain/entities/places_search_result.dart';
import '../../domain/entities/prospect.dart';

/// Client Edge `search-sirene` (discovery registre, Phase 9).
class SireneSearchService {
  SireneSearchService(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<PlacesSearchResult> search({
    required String campaignId,
    required String city,
    required String sector,
    required int radiusKm,
    int maxResults = 20,
  }) async {
    final response = await _client.functions.invoke(
      'search-sirene',
      body: {
        'city': city,
        'sector': sector,
        'radiusKm': radiusKm,
        'maxResults': maxResults,
      },
    );

    if (response.status != 200) {
      final err = response.data is Map ? response.data['error'] : response.data;
      throw Exception(err ?? 'Erreur search-sirene (${response.status})');
    }

    final data = response.data as Map<String, dynamic>;
    final raw = (data['prospects'] as List?) ?? [];
    final prospects = raw.map((item) {
      final m = item as Map<String, dynamic>;
      return Prospect(
        id: _uuid.v4(),
        campaignId: campaignId,
        name: m['name'] as String? ?? 'Sans nom',
        city: m['city'] as String?,
        address: m['address'] as String?,
        category: m['category'] as String?,
        siren: m['siren'] as String?,
        siret: m['siret'] as String?,
        nafCode: m['naf_code'] as String?,
        legalForm: m['legal_form'] as String?,
        creationDate: _parseDate(m['creation_date']),
        // Identité registre = match certain → BODACC manuel éligible.
        sireneMatchScore: 100,
        sireneMatchAmbiguous: false,
        status: ProspectStatus.newProspect,
        enrichmentSource: 'sirene',
        enrichedAt: DateTime.now(),
      );
    }).toList();

    return PlacesSearchResult(
      prospects: prospects,
      fromCache: data['fromCache'] as bool? ?? false,
      count: data['count'] as int? ?? prospects.length,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
