import 'package:localhunter/features/prospects/domain/entities/prospect.dart';
import 'package:localhunter/features/scoring/domain/entities/criterion_rule.dart';
import 'package:localhunter/features/scoring/domain/entities/grid_config.dart';
import 'package:localhunter/features/scoring/domain/entities/scoring_grid.dart';
import 'package:localhunter/features/scoring/data/grids/default_scoring_grids.dart';

/// Prospects et grilles minimales pour figer le comportement actuel du moteur.
class ScoringFixtures {
  static Prospect bare({
    String id = 'p1',
    String name = 'Boulangerie Dupont',
    String? category,
    String? phone,
    String? email,
    String? website,
    String? managerName,
    double? googleRating,
    int googleReviews = 0,
    bool isExcluded = false,
    int? pagespeedScore,
  }) {
    return Prospect(
      id: id,
      campaignId: 'c1',
      name: name,
      city: 'Albi',
      category: category,
      phone: phone,
      email: email,
      website: website,
      managerName: managerName,
      googleRating: googleRating,
      googleReviews: googleReviews,
      isExcluded: isExcluded,
      pagespeedScore: pagespeedScore,
    );
  }

  static ScoringGrid localHunter() =>
      DefaultScoringGrids.localHunterDefault(userId: 'u1');

  /// Grille à un seul composant (règle champ) — isole le calcul /100.
  static ScoringGrid phoneOnlyGrid({
    int maxPoints = 25,
    bool active = true,
    GridRecommendationConfig? recommendationConfig,
    String offerLabel = 'Pose de parquet',
  }) {
    return ScoringGrid(
      id: 'grid-phone',
      userId: 'u1',
      name: 'Phone only',
      offerLabel: offerLabel,
      exclusionConfig: const GridExclusionConfig(),
      recommendationConfig:
          recommendationConfig ?? const GridRecommendationConfig(),
      criteria: [
        ScoringCriterion(
          key: 'has_phone',
          label: 'Téléphone',
          kind: CriterionKind.component,
          maxPoints: maxPoints,
          isActive: active,
          rule: const CriterionRule(
            type: CriterionRuleType.prospectField,
            field: 'phone',
            presenceOnly: true,
          ),
        ),
      ],
    );
  }
}
