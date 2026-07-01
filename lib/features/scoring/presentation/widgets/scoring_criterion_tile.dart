import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/scoring_grid.dart';
import '../utils/criterion_hints.dart';
import 'criterion_rule_editor.dart';

class ScoringCriterionTile extends StatelessWidget {
  const ScoringCriterionTile({
    super.key,
    required this.criterion,
    required this.onChanged,
    required this.onRemove,
    this.canRemove = true,
    this.readOnly = false,
  });

  final ScoringCriterion criterion;
  final ValueChanged<ScoringCriterion> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final isSubScore = criterion.kind == CriterionKind.subScore;
    final isComponent = criterion.kind == CriterionKind.component;
    final showRuleEditor =
        criterion.rule.type != CriterionRuleType.legacy ||
        !criterionHints.containsKey(criterion.key);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: criterion.label,
                    enabled: !readOnly,
                    decoration: const InputDecoration(
                      labelText: 'Intitulé du critère',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final label = v.trim().isEmpty
                          ? criterion.label
                          : v.trim();
                      onChanged(criterion.copyWith(label: label));
                    },
                  ),
                ),
                Switch(
                  value: criterion.isActive,
                  onChanged: readOnly
                      ? null
                      : (v) => onChanged(criterion.copyWith(isActive: v)),
                ),
                if (canRemove && !readOnly)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.highPriority,
                    ),
                    tooltip: 'Supprimer le critère',
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<CriterionKind>(
              initialValue: criterion.kind,
              decoration: const InputDecoration(
                labelText: 'Type',
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: CriterionKind.component,
                  child: Text(kindLabel(CriterionKind.component)),
                ),
                DropdownMenuItem(
                  value: CriterionKind.subScore,
                  child: Text(kindLabel(CriterionKind.subScore)),
                ),
              ],
              onChanged: readOnly
                  ? null
                  : (k) {
                      if (k == null) return;
                      onChanged(criterion.copyWith(kind: k));
                    },
            ),
            if (criterionHints.containsKey(criterion.key))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  hintForCriterion(criterion.key),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (isComponent || isSubScore) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(isSubScore ? 'Max étoiles' : 'Points max'),
                  ),
                  Text(
                    '${criterion.maxPoints}${isSubScore ? ' ★' : ' pts'}',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
              Slider(
                value: criterion.maxPoints.toDouble(),
                min: 0,
                max: isSubScore ? 5 : 50,
                divisions: isSubScore ? 5 : 50,
                onChanged: criterion.isActive && !readOnly
                    ? (v) => onChanged(criterion.copyWith(maxPoints: v.round()))
                    : null,
              ),
            ],
            if (isSubScore) ...[
              Row(
                children: [
                  const Expanded(child: Text('Multiplicateur')),
                  Text(
                    criterion.starMultiplier.toStringAsFixed(1),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
              Slider(
                value: criterion.starMultiplier,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                label: criterion.starMultiplier.toStringAsFixed(1),
                onChanged: criterion.isActive && !readOnly
                    ? (v) => onChanged(criterion.copyWith(starMultiplier: v))
                    : null,
              ),
            ],
            if (showRuleEditor) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              CriterionRuleEditor(
                rule: criterion.rule,
                readOnly: readOnly,
                onChanged: (rule) => onChanged(criterion.copyWith(rule: rule)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
