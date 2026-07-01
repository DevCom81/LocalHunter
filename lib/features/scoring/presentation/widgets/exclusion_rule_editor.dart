import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/grid_config.dart';

const _exclusionTypes = [
  ('known_chain', 'Chaîne connue (nom)'),
  ('hotel_group', 'Groupe hôtelier'),
  ('website_pattern', 'Motif site web'),
  ('email_pattern', 'Motif email'),
  ('sub_score_threshold', 'Seuil sous-score'),
];

class ExclusionRuleEditor extends StatelessWidget {
  const ExclusionRuleEditor({
    super.key,
    required this.rule,
    required this.subScoreKeys,
    required this.onChanged,
    this.readOnly = false,
  });

  final ExclusionRule rule;
  final List<String> subScoreKeys;
  final ValueChanged<ExclusionRule> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _exclusionTypes.any((t) => t.$1 == rule.type)
              ? rule.type
              : _exclusionTypes.first.$1,
          decoration: const InputDecoration(labelText: 'Type', isDense: true),
          items: _exclusionTypes
              .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
              .toList(),
          onChanged: readOnly
              ? null
              : (v) {
                  if (v == null) return;
                  onChanged(_defaultForType(v));
                },
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._params(),
      ],
    );
  }

  ExclusionRule _defaultForType(String type) {
    return switch (type) {
      'known_chain' => ExclusionRule(type: type, keywords: ['mcdo']),
      'hotel_group' => ExclusionRule(
        type: type,
        categoryKeyword: 'hotel',
        nameKeywords: ['mercure'],
      ),
      'website_pattern' => ExclusionRule(type: type, patterns: ['.fr/fr/']),
      'email_pattern' => ExclusionRule(type: type, patterns: ['@corp.']),
      'sub_score_threshold' => ExclusionRule(
        type: type,
        criterionKey: subScoreKeys.firstOrNull ?? 'digital_maturity',
        minStars: 4,
      ),
      _ => ExclusionRule(type: type),
    };
  }

  List<Widget> _params() {
    switch (rule.type) {
      case 'known_chain':
        return [
          _commaField(
            label: 'Mots-clés (nom)',
            values: rule.keywords,
            onParsed: (v) => onChanged(rule.copyWith(keywords: v)),
          ),
        ];
      case 'hotel_group':
        return [
          _textField(
            label: 'Mot-clé catégorie',
            value: rule.categoryKeyword ?? '',
            onChanged: (v) => onChanged(rule.copyWith(categoryKeyword: v)),
          ),
          _commaField(
            label: 'Mots-clés nom',
            values: rule.nameKeywords,
            onParsed: (v) => onChanged(rule.copyWith(nameKeywords: v)),
          ),
        ];
      case 'website_pattern':
      case 'email_pattern':
        return [
          _commaField(
            label: 'Motifs',
            values: rule.patterns,
            onParsed: (v) => onChanged(rule.copyWith(patterns: v)),
          ),
        ];
      case 'sub_score_threshold':
        return [
          DropdownButtonFormField<String>(
            initialValue: subScoreKeys.contains(rule.criterionKey)
                ? rule.criterionKey
                : subScoreKeys.firstOrNull,
            decoration: const InputDecoration(
              labelText: 'Sous-score',
              isDense: true,
            ),
            items: subScoreKeys
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: readOnly
                ? null
                : (v) => onChanged(rule.copyWith(criterionKey: v)),
          ),
          _numberField(
            label: 'Seuil minimum (★)',
            value: rule.minStars,
            onChanged: (v) => onChanged(rule.copyWith(minStars: v)),
          ),
        ];
      default:
        return [
          Text(
            'Type « ${rule.type} » — édition manuelle non disponible.',
            style: const TextStyle(fontSize: 13),
          ),
        ];
    }
  }

  Widget _textField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      enabled: !readOnly,
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: onChanged,
    );
  }

  Widget _commaField({
    required String label,
    required List<String> values,
    required ValueChanged<List<String>> onParsed,
  }) {
    return TextFormField(
      initialValue: values.join(', '),
      enabled: !readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'mot1, mot2, …',
        isDense: true,
      ),
      onChanged: (v) => onParsed(
        v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      ),
    );
  }

  Widget _numberField({
    required String label,
    required double? value,
    required ValueChanged<double?> onChanged,
  }) {
    return TextFormField(
      initialValue: value?.toString(),
      enabled: !readOnly,
      decoration: InputDecoration(labelText: label, isDense: true),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => onChanged(double.tryParse(v)),
    );
  }
}
