import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/prospect.dart';

/// Données d'enrichissement d'un prospect (SIRENE + PageSpeed),
/// renvoyées par l'Edge Function `enrich-prospects`.
class ProspectEnrichment {
  const ProspectEnrichment({
    this.siren,
    this.siret,
    this.nafCode,
    this.legalForm,
    this.creationDate,
    this.active,
    this.pagespeedScore,
    this.managerName,
    this.annualRevenue,
    this.annualRevenueYear,
    this.netIncome,
  });

  factory ProspectEnrichment.fromJson(Map<String, dynamic> json) {
    final rawDate = json['creation_date'] as String?;
    return ProspectEnrichment(
      siren: json['siren'] as String?,
      siret: json['siret'] as String?,
      nafCode: json['naf_code'] as String?,
      legalForm: json['legal_form'] as String?,
      creationDate: rawDate != null ? DateTime.tryParse(rawDate) : null,
      active: json['active'] as bool?,
      pagespeedScore: json['pagespeed_score'] as int?,
      managerName: json['manager_name'] as String?,
      annualRevenue: (json['annual_revenue'] as num?)?.toInt(),
      annualRevenueYear: json['annual_revenue_year'] as int?,
      netIncome: (json['net_income'] as num?)?.toInt(),
    );
  }

  final String? siren;
  final String? siret;
  final String? nafCode;
  final String? legalForm;
  final DateTime? creationDate;

  /// false = établissement fermé au répertoire SIRENE.
  final bool? active;
  final int? pagespeedScore;

  /// Dirigeant principal (API Recherche d'entreprises).
  final String? managerName;

  /// Dernier bilan publié à l'INPI, en euros.
  final int? annualRevenue;
  final int? annualRevenueYear;
  final int? netIncome;

  Prospect applyTo(Prospect prospect) {
    final closed = active == false;
    return prospect.copyWith(
      siren: siren,
      siret: siret,
      nafCode: nafCode,
      legalForm: legalForm,
      creationDate: creationDate,
      pagespeedScore: pagespeedScore,
      managerName: managerName,
      annualRevenue: annualRevenue,
      annualRevenueYear: annualRevenueYear,
      netIncome: netIncome,
      enrichedAt: DateTime.now(),
      isExcluded: closed ? true : null,
      exclusionReason: closed ? 'Établissement fermé (SIRENE)' : null,
    );
  }
}

/// Appelle l'Edge Function `enrich-prospects`. Best-effort : toute erreur
/// renvoie une map vide, la recherche de prospects n'est jamais bloquée.
class ProspectEnrichmentService {
  ProspectEnrichmentService(this._client);

  final SupabaseClient _client;

  Future<Map<String, ProspectEnrichment>> enrich({
    required String city,
    required List<Prospect> prospects,
  }) async {
    if (prospects.isEmpty) return {};
    try {
      final response = await _client.functions.invoke(
        'enrich-prospects',
        body: {
          'city': city,
          'prospects': [
            for (final p in prospects)
              {'id': p.id, 'name': p.name, 'website': p.website},
          ],
        },
      );
      if (response.status != 200) {
        debugPrint('enrich-prospects: HTTP ${response.status}');
        return {};
      }
      final data = response.data as Map<String, dynamic>;
      final enriched = data['enriched'] as Map<String, dynamic>? ?? {};
      return enriched.map(
        (id, json) => MapEntry(
          id,
          ProspectEnrichment.fromJson(json as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      debugPrint('enrich-prospects: $e');
      return {};
    }
  }
}
