import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/prospect.dart';

/// Données d'enrichissement d'un prospect (SIRENE + site + PageSpeed),
/// renvoyées par l'Edge Function `enrich-prospects`.
class ProspectEnrichment {
  const ProspectEnrichment({
    this.siren,
    this.siret,
    this.nafCode,
    this.legalForm,
    this.creationDate,
    this.active,
    this.matchScore,
    this.matchAmbiguous = false,
    this.pagespeedScore,
    this.websiteReachable,
    this.websiteHttps,
    this.websiteHttpStatus,
    this.websiteTitle,
    this.websiteHasViewport,
    this.managerName,
    this.annualRevenue,
    this.annualRevenueYear,
    this.netIncome,
    this.employeeCount,
    this.establishmentCount,
    this.socialChecked,
    this.facebookUrl,
    this.instagramUrl,
    this.linkedinUrl,
    this.tiktokUrl,
    this.youtubeUrl,
    this.xUrl,
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
      matchScore: (json['match_score'] as num?)?.toInt(),
      matchAmbiguous: json['match_ambiguous'] as bool? ?? false,
      pagespeedScore: json['pagespeed_score'] as int?,
      websiteReachable: json['website_reachable'] as bool?,
      websiteHttps: json['website_https'] as bool?,
      websiteHttpStatus: (json['website_http_status'] as num?)?.toInt(),
      websiteTitle: json['website_title'] as String?,
      websiteHasViewport: json['website_has_viewport'] as bool?,
      managerName: json['manager_name'] as String?,
      annualRevenue: (json['annual_revenue'] as num?)?.toInt(),
      annualRevenueYear: json['annual_revenue_year'] as int?,
      netIncome: (json['net_income'] as num?)?.toInt(),
      employeeCount: (json['employee_count'] as num?)?.toInt(),
      establishmentCount: (json['establishment_count'] as num?)?.toInt(),
      socialChecked: json['social_checked'] as bool?,
      facebookUrl: json['facebook_url'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      tiktokUrl: json['tiktok_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      xUrl: json['x_url'] as String?,
    );
  }

  final String? siren;
  final String? siret;
  final String? nafCode;
  final String? legalForm;
  final DateTime? creationDate;
  final bool? active;
  final int? matchScore;
  final bool matchAmbiguous;
  final int? pagespeedScore;
  final bool? websiteReachable;
  final bool? websiteHttps;
  final int? websiteHttpStatus;
  final String? websiteTitle;
  final bool? websiteHasViewport;
  final String? managerName;
  final int? annualRevenue;
  final int? annualRevenueYear;
  final int? netIncome;
  final int? employeeCount;
  final int? establishmentCount;
  final bool? socialChecked;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? linkedinUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final String? xUrl;

  Prospect applyTo(Prospect prospect) {
    final closed = active == false;
    final base = prospect.copyWith(
      siren: siren,
      siret: siret,
      nafCode: nafCode,
      legalForm: legalForm,
      creationDate: creationDate,
      pagespeedScore: pagespeedScore,
      websiteReachable: websiteReachable,
      websiteHttps: websiteHttps,
      websiteHttpStatus: websiteHttpStatus,
      websiteTitle: websiteTitle,
      websiteHasViewport: websiteHasViewport,
      managerName: managerName,
      annualRevenue: annualRevenue,
      annualRevenueYear: annualRevenueYear,
      netIncome: netIncome,
      employeeCount: employeeCount,
      establishmentCount: establishmentCount,
      sireneMatchScore: matchScore,
      sireneMatchAmbiguous: matchAmbiguous,
      enrichedAt: DateTime.now(),
      isExcluded: closed ? true : null,
      exclusionReason: closed ? 'Établissement fermé (SIRENE)' : null,
    );
    if (socialChecked != true) return base;
    // Écrase les URLs (y compris null) : scan fait ≠ conserver d'anciennes valeurs.
    return Prospect(
      id: base.id,
      campaignId: base.campaignId,
      name: base.name,
      city: base.city,
      address: base.address,
      managerName: base.managerName,
      email: base.email,
      phone: base.phone,
      website: base.website,
      facebookUrl: facebookUrl,
      instagramUrl: instagramUrl,
      linkedinUrl: linkedinUrl,
      tiktokUrl: tiktokUrl,
      youtubeUrl: youtubeUrl,
      xUrl: xUrl,
      socialCheckedAt: DateTime.now(),
      googleRating: base.googleRating,
      googleReviews: base.googleReviews,
      category: base.category,
      status: base.status,
      isExcluded: base.isExcluded,
      exclusionReason: base.exclusionReason,
      siren: base.siren,
      siret: base.siret,
      nafCode: base.nafCode,
      legalForm: base.legalForm,
      creationDate: base.creationDate,
      pagespeedScore: base.pagespeedScore,
      websiteReachable: base.websiteReachable,
      websiteHttps: base.websiteHttps,
      websiteHttpStatus: base.websiteHttpStatus,
      websiteTitle: base.websiteTitle,
      websiteHasViewport: base.websiteHasViewport,
      annualRevenue: base.annualRevenue,
      annualRevenueYear: base.annualRevenueYear,
      netIncome: base.netIncome,
      employeeCount: base.employeeCount,
      establishmentCount: base.establishmentCount,
      sireneMatchScore: base.sireneMatchScore,
      sireneMatchAmbiguous: base.sireneMatchAmbiguous,
      googlePlaceId: base.googlePlaceId,
      googleBusinessStatus: base.googleBusinessStatus,
      bodaccFetchedAt: base.bodaccFetchedAt,
      bodaccLastEventAt: base.bodaccLastEventAt,
      bodaccNoResults: base.bodaccNoResults,
      bodaccHasCreation: base.bodaccHasCreation,
      bodaccHasAccountsFiling: base.bodaccHasAccountsFiling,
      bodaccHasModification: base.bodaccHasModification,
      bodaccHasSale: base.bodaccHasSale,
      bodaccHasRadiation: base.bodaccHasRadiation,
      bodaccHasLiquidation: base.bodaccHasLiquidation,
      bodaccHasCollectiveProceeding: base.bodaccHasCollectiveProceeding,
      bodaccHasManagerChange: base.bodaccHasManagerChange,
      bodaccHasAddressChange: base.bodaccHasAddressChange,
      bodaccSignalConfidence: base.bodaccSignalConfidence,
      bodaccRadiationStatus: base.bodaccRadiationStatus,
      enrichedAt: base.enrichedAt,
      enrichmentSource: base.enrichmentSource,
      createdAt: base.createdAt,
      customFields: base.customFields,
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
    required List<String> enabledProviders,
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
          'enabledProviders': enabledProviders,
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
