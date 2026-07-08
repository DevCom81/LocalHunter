import '../entities/subscription_tier.dart';

/// Lecture seule : le niveau d'abonnement n'est jamais modifiable depuis
/// l'app (changement manuel via le Dashboard Supabase en attendant la
/// monétisation Google Play).
abstract class SubscriptionRepository {
  Future<SubscriptionTier> getTier(String userId);
}
