import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/prospect_status.dart';
import '../../domain/entities/prospect.dart';
import '../../domain/repositories/prospect_repository.dart';
import '../../../scoring/domain/entities/prospect_score.dart';
import '../models/prospect_dto.dart';
import '../models/prospect_score_dto.dart';
import '../models/prospect_score_mapper.dart';

class SupabaseProspectRepository implements ProspectRepository {
  SupabaseProspectRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Prospect>> getByCampaign(String campaignId) async {
    final rows = await _client
        .from('prospects')
        .select()
        .eq('campaign_id', campaignId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => prospectFromDto(ProspectDto.fromJson(r)))
        .toList();
  }

  @override
  Future<Prospect?> getById(String id) async {
    final row = await _client.from('prospects').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return prospectFromDto(ProspectDto.fromJson(row));
  }

  @override
  Future<void> updateStatus(String id, ProspectStatus status) async {
    await _client
        .from('prospects')
        .update({'status': status.dbValue})
        .eq('id', id);
  }

  @override
  Future<void> updateExclusion(
    String id, {
    required bool isExcluded,
    String? exclusionReason,
    ProspectStatus? status,
  }) async {
    await _client.from('prospects').update({
      'is_excluded': isExcluded,
      'exclusion_reason': exclusionReason,
      if (status != null) 'status': status.dbValue,
    }).eq('id', id);
  }

  @override
  Future<List<Prospect>> importProspects(
    String campaignId,
    List<Prospect> prospects,
  ) async {
    if (prospects.isEmpty) return [];
    final payload = prospects
        .map((p) => ProspectDto(
              id: p.id,
              campaignId: campaignId,
              name: p.name,
              city: p.city,
              address: p.address,
              managerName: p.managerName,
              email: p.email,
              phone: p.phone,
              website: p.website,
              facebookUrl: p.facebookUrl,
              instagramUrl: p.instagramUrl,
              linkedinUrl: p.linkedinUrl,
              tiktokUrl: p.tiktokUrl,
              youtubeUrl: p.youtubeUrl,
              xUrl: p.xUrl,
              socialCheckedAt: p.socialCheckedAt,
              googleRating: p.googleRating,
              googleReviews: p.googleReviews,
              category: p.category,
              status: p.status.dbValue,
              isExcluded: p.isExcluded,
              exclusionReason: p.exclusionReason,
              siren: p.siren,
              siret: p.siret,
              nafCode: p.nafCode,
              legalForm: p.legalForm,
              creationDate: p.creationDate,
              pagespeedScore: p.pagespeedScore,
              websiteReachable: p.websiteReachable,
              websiteHttps: p.websiteHttps,
              websiteHttpStatus: p.websiteHttpStatus,
              websiteTitle: p.websiteTitle,
              websiteHasViewport: p.websiteHasViewport,
              annualRevenue: p.annualRevenue,
              annualRevenueYear: p.annualRevenueYear,
              netIncome: p.netIncome,
              employeeCount: p.employeeCount,
              establishmentCount: p.establishmentCount,
              sireneMatchScore: p.sireneMatchScore,
              sireneMatchAmbiguous: p.sireneMatchAmbiguous,
              googleBusinessStatus: p.googleBusinessStatus,
              bodaccFetchedAt: p.bodaccFetchedAt,
              bodaccLastEventAt: p.bodaccLastEventAt,
              bodaccNoResults: p.bodaccNoResults,
              bodaccHasCreation: p.bodaccHasCreation,
              bodaccHasAccountsFiling: p.bodaccHasAccountsFiling,
              bodaccHasModification: p.bodaccHasModification,
              bodaccHasSale: p.bodaccHasSale,
              bodaccHasRadiation: p.bodaccHasRadiation,
              bodaccHasLiquidation: p.bodaccHasLiquidation,
              bodaccHasCollectiveProceeding: p.bodaccHasCollectiveProceeding,
              bodaccHasManagerChange: p.bodaccHasManagerChange,
              bodaccHasAddressChange: p.bodaccHasAddressChange,
              bodaccSignalConfidence: p.bodaccSignalConfidence,
              bodaccRadiationStatus: p.bodaccRadiationStatus,
              enrichedAt: p.enrichedAt,
              customFields: Map<String, String>.from(p.customFields),
            ).toInsertJson())
        .toList();

    // Garantie runtime : custom_fields jamais null dans le payload.
    for (final row in payload) {
      final cf = row['custom_fields'];
      if (cf == null || cf is! Map) {
        row['custom_fields'] = <String, dynamic>{};
      } else {
        row['custom_fields'] = Map<String, dynamic>.from(cf);
      }
    }

    // Insert bulk : defaultToNull=true (défaut SDK) force NULL sur les colonnes
    // absentes d'une ligne du lot → casse custom_fields NOT NULL DEFAULT '{}'.
    final rows = await _client
        .from('prospects')
        .insert(payload, defaultToNull: false)
        .select();
    return (rows as List)
        .map((r) => prospectFromDto(ProspectDto.fromJson(r)))
        .toList();
  }

  @override
  Future<void> saveScores(List<ProspectScore> scores) async {
    if (scores.isEmpty) return;
    final payload =
        scores.map((s) => prospectScoreToDto(s).toInsertJson()).toList();
    await _client.from('prospect_scores').upsert(payload);
  }

  @override
  Future<Map<String, ProspectScore>> getScoresByCampaign(
    String campaignId,
  ) async {
    final prospects = await getByCampaign(campaignId);
    if (prospects.isEmpty) return {};
    final ids = prospects.map((p) => p.id).toList();
    final rows = await _client
        .from('prospect_scores')
        .select()
        .inFilter('prospect_id', ids);

    final result = <String, ProspectScore>{};
    for (final row in rows as List) {
      final dto = ProspectScoreDto.fromJson(row);
      result[dto.prospectId] =
          prospectScoreFromDto(dto, id: row['id'] as String?);
    }
    return result;
  }
}
