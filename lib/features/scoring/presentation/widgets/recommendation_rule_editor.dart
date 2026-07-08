import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/grid_config.dart';

class RecommendationRuleEditor extends StatelessWidget {
  const RecommendationRuleEditor({
    super.key,
    required this.rule,
    required this.subScoreKeys,
    required this.onChanged,
    this.readOnly = false,
  });

  final RecommendationRule rule;
  final List<String> subScoreKeys;
  final ValueChanged<RecommendationRule> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final keys = subScoreKeys.isEmpty ? [rule.criterionKey] : subScoreKeys;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: keys.contains(rule.criterionKey)
              ? rule.criterionKey
              : keys.first,
          decoration: const InputDecoration(
            labelText: 'Sous-score',
            isDense: true,
          ),
          items: keys
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: readOnly
              ? null
              : (v) {
                  if (v != null) onChanged(rule.copyWith(criterionKey: v));
                },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: rule.minStars.toString(),
          enabled: !readOnly,
          decoration: const InputDecoration(
            labelText: 'Seuil minimum (★)',
            isDense: true,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null) onChanged(rule.copyWith(minStars: parsed));
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: rule.categoryKeyword,
          enabled: !readOnly,
          decoration: const InputDecoration(
            labelText: 'Filtre catégorie (optionnel)',
            hintText: 'ex. rest, bar',
            isDense: true,
          ),
          onChanged: (v) => onChanged(
            rule.copyWith(categoryKeyword: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
      ],
    );
  }
}
