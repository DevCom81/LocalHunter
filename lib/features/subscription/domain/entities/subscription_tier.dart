enum SubscriptionTier {
  freemium(
    'freemium',
    'Freemium',
    'Gratuit',
    PlanLimits(
      maxCampaigns: 1,
      maxGrids: 1,
      maxProspectsPerCampaign: 5,
    ),
  ),
  premium(
    'premium',
    'Premium',
    '19,99 € / mois',
    PlanLimits(
      maxCampaigns: 5,
      maxGrids: 2,
      maxAiGenerationsPerMonth: 2,
      maxProspectsPerCampaign: 20,
    ),
    playProductId: 'localhunter_premium_monthly',
  ),
  premiumPlus(
    'premium_plus',
    'Premium Plus',
    '39,99 € / mois',
    PlanLimits(
      maxCampaigns: 10,
      maxGrids: 5,
      maxAiGenerationsPerMonth: 5,
      maxProspectsPerCampaign: 50,
    ),
    playProductId: 'localhunter_premium_plus_monthly',
  ),
  pro(
    'pro',
    'Pro Plan',
    '69,99 € / mois',
    PlanLimits.unlimited,
    playProductId: 'localhunter_pro_monthly',
  );

  const SubscriptionTier(
    this.dbValue,
    this.label,
    this.priceLabel,
    this.limits, {
    this.playProductId,
  });

  final String dbValue;
  final String label;
  final String priceLabel;
  final PlanLimits limits;
  final String? playProductId;

  static Set<String> get playProductIds => {
        for (final tier in values)
          if (tier.playProductId != null) tier.playProductId!,
      };

  static SubscriptionTier fromDb(String? value) {
    return switch (value) {
      'premium' => SubscriptionTier.premium,
      'premium_plus' => SubscriptionTier.premiumPlus,
      'pro' => SubscriptionTier.pro,
      _ => SubscriptionTier.freemium,
    };
  }

  static SubscriptionTier? fromPlayProductId(String productId) {
    for (final tier in values) {
      if (tier.playProductId == productId) return tier;
    }
    return null;
  }

  bool get isPaid => this != SubscriptionTier.freemium;

  int get rank => index;
}

/// Quotas par palier. `null` = illimité (Pro Plan).
class PlanLimits {
  const PlanLimits({
    this.maxCampaigns,
    this.maxGrids,
    this.maxAiGenerationsPerMonth,
    this.maxProspectsPerCampaign,
  });

  static const unlimited = PlanLimits();

  final int? maxCampaigns;
  final int? maxGrids;
  final int? maxAiGenerationsPerMonth;
  final int? maxProspectsPerCampaign;

  static const upgradeMessage = 'Pour plus de résultats, abonnez-vous.';
}
