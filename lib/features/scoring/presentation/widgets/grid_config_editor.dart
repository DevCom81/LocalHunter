import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/offer_types.dart';
import '../../domain/entities/grid_config.dart';
import '../../domain/entities/scoring_grid.dart';
import 'exclusion_rule_editor.dart';
import 'recommendation_rule_editor.dart';

class GridConfigEditor extends StatelessWidget {
  const GridConfigEditor({
    super.key,
    required this.grid,
    required this.onExclusionChanged,
    required this.onRecommendationChanged,
    this.readOnly = false,
  });

  final ScoringGrid grid;
  final ValueChanged<GridExclusionConfig> onExclusionChanged;
  final ValueChanged<GridRecommendationConfig> onRecommendationChanged;
  final bool readOnly;

  List<String> get _subScoreKeys => grid.criteria
      .where((c) => c.kind == CriterionKind.subScore)
      .map((c) => c.key)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exclusions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Règles qui mettent le score global à 0. Évaluées en ordre (premier '
          'match gagne). Combinaisons AND/OR : reporté à une phase ultérieure.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...grid.exclusionConfig.rules.asMap().entries.map((e) {
          return _ruleCard(
            context,
            onDelete: readOnly
                ? null
                : () => _updateExclusionRules(
                      List<ExclusionRule>.from(grid.exclusionConfig.rules)
                        ..removeAt(e.key),
                    ),
            child: ExclusionRuleEditor(
              rule: e.value,
              subScoreKeys: _subScoreKeys,
              readOnly: readOnly,
              onChanged: (updated) {
                final rules = List<ExclusionRule>.from(
                  grid.exclusionConfig.rules,
                );
                rules[e.key] = updated;
                _updateExclusionRules(rules);
              },
            ),
          );
        }),
        if (!readOnly) _exclusionPresets(),
        const SizedBox(height: AppSpacing.lg),
        Text('Recommandations offre',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Si un sous-score atteint le seuil, l\'offre est recommandée.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...grid.recommendationConfig.rules.asMap().entries.map((e) {
          return _ruleCard(
            context,
            onDelete: readOnly
                ? null
                : () => _updateRecommendationRules(
                      List<RecommendationRule>.from(
                        grid.recommendationConfig.rules,
                      )..removeAt(e.key),
                    ),
            child: RecommendationRuleEditor(
              rule: e.value,
              subScoreKeys: _subScoreKeys,
              readOnly: readOnly,
              onChanged: (updated) {
                final rules = List<RecommendationRule>.from(
                  grid.recommendationConfig.rules,
                );
                rules[e.key] = updated;
                _updateRecommendationRules(rules);
              },
            ),
          );
        }),
        if (!readOnly)
          ActionChip(
            label: const Text('+ Règle recommandation'),
            onPressed: () => _updateRecommendationRules([
              ...grid.recommendationConfig.rules,
              RecommendationRule(
                criterionKey: _subScoreKeys.firstOrNull ?? 'site_score',
                minStars: 3,
                offerType: OfferType.website,
              ),
            ]),
          ),
      ],
    );
  }

  Widget _ruleCard(
    BuildContext context, {
    required Widget child,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onDelete != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Supprimer',
                  onPressed: onDelete,
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _exclusionPresets() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ActionChip(
          label: const Text('+ Chaîne connue'),
          onPressed: () => _addExclusion(
            ExclusionRule(type: 'known_chain', keywords: ['mcdo']),
          ),
        ),
        ActionChip(
          label: const Text('+ Groupe hôtelier'),
          onPressed: () => _addExclusion(
            ExclusionRule(
              type: 'hotel_group',
              categoryKeyword: 'hotel',
              nameKeywords: ['mercure'],
            ),
          ),
        ),
        ActionChip(
          label: const Text('+ Motif site'),
          onPressed: () => _addExclusion(
            ExclusionRule(type: 'website_pattern', patterns: ['.fr/fr/']),
          ),
        ),
        ActionChip(
          label: const Text('+ Maturité digitale'),
          onPressed: () => _addExclusion(
            ExclusionRule(
              type: 'sub_score_threshold',
              criterionKey: 'digital_maturity',
              minStars: 4,
            ),
          ),
        ),
      ],
    );
  }

  void _addExclusion(ExclusionRule rule) {
    _updateExclusionRules([...grid.exclusionConfig.rules, rule]);
  }

  void _updateExclusionRules(List<ExclusionRule> rules) {
    onExclusionChanged(grid.exclusionConfig.copyWith(rules: rules));
  }

  void _updateRecommendationRules(List<RecommendationRule> rules) {
    onRecommendationChanged(grid.recommendationConfig.copyWith(rules: rules));
  }
}
