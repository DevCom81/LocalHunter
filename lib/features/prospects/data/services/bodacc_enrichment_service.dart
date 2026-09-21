import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/prospect.dart';
import '../../domain/services/bodacc_selection.dart';

/// Appel Edge `enrich-bodacc`. Persistance faite côté serveur.
/// Best-effort : les erreurs ne remontent pas comme échec campagne.
class BodaccEnrichmentService {
  BodaccEnrichmentService(this._client);

  final SupabaseClient _client;

  static const maxProspects = 20;

  /// Retourne les ids effectivement enrichis.
  Future<List<String>> enrich({
    required List<Prospect> prospects,
    bool forceRefresh = false,
  }) async {
    if (prospects.isEmpty) return const [];
    final payload = prospects.take(maxProspects).map((p) {
      final siren = BodaccSelection.resolveSiren(p) ?? '';
      return {
        'id': p.id,
        'siren': siren,
        // Fermé SIRENE → false ; sinon true (éligibles non exclus).
        'sireneActive': !p.isExcluded,
      };
    }).where((m) => (m['siren'] as String).length == 9).toList();

    if (payload.isEmpty) return const [];

    try {
      final response = await _client.functions.invoke(
        'enrich-bodacc',
        body: {
          'prospects': payload,
          'forceRefresh': forceRefresh,
        },
      );
      if (response.status != 200) {
        debugPrint('enrich-bodacc: HTTP ${response.status}');
        return const [];
      }
      final data = response.data as Map<String, dynamic>?;
      final enriched = data?['enriched'] as Map<String, dynamic>? ?? {};
      return enriched.keys.toList();
    } catch (e) {
      debugPrint('enrich-bodacc: $e');
      return const [];
    }
  }
}
