enum SubscriptionTier {
  freemium('freemium', 'Freemium'),
  premium('premium', 'Premium');

  const SubscriptionTier(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static SubscriptionTier fromDb(String? value) {
    return value == 'premium'
        ? SubscriptionTier.premium
        : SubscriptionTier.freemium;
  }

  bool get isPremium => this == SubscriptionTier.premium;
}

/// Quotas de l'offre gratuite. Le serveur applique les mêmes limites
/// (triggers SQL + Edge Function) : l'UI ne fait qu'anticiper proprement.
abstract final class FreemiumLimits {
  static const maxCampaigns = 1;
  static const maxGrids = 1;
  static const maxProspectsPerCampaign = 5;

  static const upgradeMessage = 'Pour plus de résultats, abonnez-vous.';
}

/// Prix affiché à titre indicatif en attendant Google Play Billing.
const premiumMonthlyPriceLabel = '39,99 € / mois';
