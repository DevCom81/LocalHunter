import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/prospect_status.dart';
import '../../domain/entities/places_search_result.dart';
import '../../domain/entities/prospect.dart';

class PlacesSearchService {
  PlacesSearchService(this._client);

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
      'search-places',
      body: {
        'city': city,
        'sector': sector,
        'radiusKm': radiusKm,
        'maxResults': maxResults,
      },
    );

    if (response.status != 200) {
      final err = response.data is Map ? response.data['error'] : response.data;
      throw Exception(err ?? 'Erreur search-places (${response.status})');
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
        phone: m['phone'] as String?,
        website: m['website'] as String?,
        googleRating: (m['google_rating'] as num?)?.toDouble(),
        googleReviews: m['google_reviews'] as int? ?? 0,
        category: m['category'] as String?,
        googlePlaceId: m['google_place_id'] as String?,
        status: ProspectStatus.newProspect,
        enrichmentSource: 'google_places',
        enrichedAt: DateTime.now(),
      );
    }).toList();

    return PlacesSearchResult(
      prospects: prospects,
      fromCache: data['fromCache'] as bool? ?? false,
      count: data['count'] as int? ?? prospects.length,
    );
  }
}
