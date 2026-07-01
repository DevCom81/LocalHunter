import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/prospect.dart';
import '../../domain/repositories/prospect_repository.dart';
import '../../../scoring/domain/entities/prospect_score.dart';
import '../models/prospect_dto.dart';
import '../models/prospect_score_dto.dart';

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
              googleRating: p.googleRating,
              googleReviews: p.googleReviews,
              category: p.category,
              status: p.status.dbValue,
              isExcluded: p.isExcluded,
              exclusionReason: p.exclusionReason,
              customFields: p.customFields,
            ).toInsertJson())
        .toList();

    final rows = await _client.from('prospects').insert(payload).select();
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
