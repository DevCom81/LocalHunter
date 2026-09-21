import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/scoring_grid.dart';
import '../../domain/measurable_criteria_catalog.dart';

/// Validation post-IA : rejette tout critère non mesurable (Phase 11).
///
/// Ne modifie pas les grilles déjà persistées — uniquement le parsing
/// des grilles fraîchement générées.
class GeneratedGridValidator {
  const GeneratedGridValidator();

  /// Conserve uniquement les critères alimentables. [rejectedKeys] pour logs.
  ({List<ScoringCriterion> kept, List<String> rejectedKeys}) filterCriteria(
    List<ScoringCriterion> criteria,
  ) {
    final kept = <ScoringCriterion>[];
    final rejected = <String>[];
    for (final c in criteria) {
      if (_isMeasurable(c)) {
        kept.add(c);
      } else {
        rejected.add(c.key);
      }
    }
    return (kept: kept, rejectedKeys: rejected);
  }

  bool _isMeasurable(ScoringCriterion c) {
    if (MeasurableCriteriaCatalog.hasForbiddenClaim(c.key, c.label)) {
      return false;
    }
    final rule = c.rule;
    switch (rule.type) {
      case CriterionRuleType.keywordMatch:
        final match = rule.match?.trim() ?? '';
        if (match.isEmpty) return false;
        if (MeasurableCriteriaCatalog.hasForbiddenClaim(c.key, match)) {
          return false;
        }
        return true;
      case CriterionRuleType.prospectField:
      case CriterionRuleType.boolean:
      case CriterionRuleType.threshold:
        return MeasurableCriteriaCatalog.isFieldMeasurable(rule.field);
      case CriterionRuleType.legacy:
        // L'IA ne doit pas produire de legacy ; rejet strict en post-génération.
        return false;
    }
  }
}
