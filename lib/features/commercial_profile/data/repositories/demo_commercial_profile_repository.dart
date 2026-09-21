import '../../domain/entities/commercial_profile.dart';
import '../../domain/repositories/commercial_profile_repository.dart';

class DemoCommercialProfileRepository implements CommercialProfileRepository {
  CommercialProfile? _profile;

  @override
  Future<CommercialProfile?> getByUserId(String userId) async {
    if (_profile?.userId != userId) return null;
    return _profile;
  }

  @override
  Future<CommercialProfile> save(
    CommercialProfile profile, {
    required bool markValidated,
  }) async {
    final nextVersion = markValidated
        ? (profile.validatedAt == null ? 1 : profile.version + 1)
        : profile.version;
    _profile = profile.copyWith(
      version: nextVersion,
      validatedAt: markValidated ? DateTime.now() : null,
      clearValidatedAt: !markValidated,
      updatedAt: DateTime.now(),
    );
    return _profile!;
  }
}
