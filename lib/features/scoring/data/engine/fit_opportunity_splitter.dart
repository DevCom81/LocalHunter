import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/scoring_grid.dart';

/// Dimension d'un critère composant pour FIT / OPPORTUNITY (Phase 8).
enum ScoreDimension { fit, opportunity }

/// Sépare les critères actifs en correspondance (FIT) vs moment (OPPORTUNITY).
///
/// OPPORTUNITY = signaux de timing / besoin détecté (BODACC, création récente,
/// opportunité site / PageSpeed…). Le reste des composants actifs = FIT.
class FitOpportunitySplitter {
  const FitOpportunitySplitter();

  ScoreDimension dimensionOf(ScoringCriterion c) {
    if (_isOpportunityKey(c.key)) return ScoreDimension.opportunity;
    final field = c.rule.field;
    if (field != null && _isOpportunityField(field)) {
      return ScoreDimension.opportunity;
    }
    if (c.rule.type == CriterionRuleType.legacy) {
      final sk = c.rule.scorerKey ?? c.key;
      if (_isOpportunityKey(sk)) return ScoreDimension.opportunity;
    }
    return ScoreDimension.fit;
  }

  /// Score 0–100 pour une dimension ; null si aucun critère pondéré.
  int? normalize({
    required ScoringGrid grid,
    required Map<String, int> componentScores,
    required ScoreDimension dimension,
    required bool isExcluded,
  }) {
    var earned = 0;
    var max = 0;
    for (final c in grid.criteria) {
      if (c.kind != CriterionKind.component || !c.isActive || c.maxPoints <= 0) {
        continue;
      }
      if (dimensionOf(c) != dimension) continue;
      max += c.maxPoints;
      earned += componentScores[c.key] ?? 0;
    }
    if (max <= 0) return null;
    if (isExcluded) return 0;
    return ((earned / max) * 100).round().clamp(0, 100);
  }

  static bool _isOpportunityKey(String key) {
    if (key.startsWith('bodacc_')) return true;
    return const {
      'website_opportunity',
      'site_score',
      'pagespeed',
    }.contains(key);
  }

  static bool _isOpportunityField(String field) {
    if (field.startsWith('bodacc_')) return true;
    return const {
      'pagespeed_score',
      'company_created_recently',
    }.contains(field);
  }
}
