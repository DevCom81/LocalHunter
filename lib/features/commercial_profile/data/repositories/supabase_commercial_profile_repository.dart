import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/commercial_profile.dart';
import '../../domain/repositories/commercial_profile_repository.dart';
import '../models/commercial_profile_dto.dart';

class SupabaseCommercialProfileRepository
    implements CommercialProfileRepository {
  SupabaseCommercialProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<CommercialProfile?> getByUserId(String userId) async {
    final row = await _client
        .from('commercial_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return profileFromDto(CommercialProfileDto.fromJson(row));
  }

  @override
  Future<CommercialProfile> save(
    CommercialProfile profile, {
    required bool markValidated,
  }) async {
    // Toute modification non validée retire le statut « validé ».
    // Chaque validation incrémente la version (traçabilité).
    final nextVersion = markValidated
        ? (profile.validatedAt == null ? 1 : profile.version + 1)
        : profile.version;

    final payload = profileToDto(profile).toUpsertJson(
      markValidated: markValidated,
    );
    payload['version'] = nextVersion;
    if (!markValidated) payload['validated_at'] = null;

    final row = await _client
        .from('commercial_profiles')
        .upsert(payload)
        .select()
        .single();
    return profileFromDto(CommercialProfileDto.fromJson(row));
  }
}
