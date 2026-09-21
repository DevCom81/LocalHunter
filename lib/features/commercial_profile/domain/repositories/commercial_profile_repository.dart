import '../entities/commercial_profile.dart';

abstract class CommercialProfileRepository {
  Future<CommercialProfile?> getByUserId(String userId);

  /// Upsert ; si [markValidated] alors validated_at = now(), sinon brouillon.
  Future<CommercialProfile> save(
    CommercialProfile profile, {
    required bool markValidated,
  });
}
