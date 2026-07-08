import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../models/campaign_dto.dart';

class SupabaseCampaignRepository implements CampaignRepository {
  SupabaseCampaignRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  @override
  Future<List<Campaign>> getAll() async {
    final rows = await _client
        .from('campaigns')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => campaignFromDto(CampaignDto.fromJson(r)))
        .toList();
  }

  @override
  Future<Campaign?> getById(String id) async {
    final row = await _client
        .from('campaigns')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (row == null) return null;
    return campaignFromDto(CampaignDto.fromJson(row));
  }

  @override
  Future<Campaign> create(CreateCampaignInput input) async {
    final row = await _client.from('campaigns').insert({
      'user_id': _userId,
      'name': input.name,
      'sector': input.sector,
      'city': input.city,
      'radius_km': input.radiusKm,
      'target_count': input.targetCount,
      if (input.scoringGridId != null) 'scoring_grid_id': input.scoringGridId,
    }).select().single();
    return campaignFromDto(CampaignDto.fromJson(row));
  }

  @override
  Future<void> delete(String id) async {
    await _client
        .from('campaigns')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
