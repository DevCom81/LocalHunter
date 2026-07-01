import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/criterion_rule.dart';
import '../../data/engine/prospect_field_resolver.dart';

class CriterionRuleEditor extends StatelessWidget {
  const CriterionRuleEditor({
    super.key,
    required this.rule,
    required this.onChanged,
    this.readOnly = false,
  });

  final CriterionRule rule;
  final ValueChanged<CriterionRule> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<CriterionRuleType>(
          initialValue: rule.type,
          decoration: const InputDecoration(
            labelText: 'Règle de calcul',
            isDense: true,
          ),
          items: CriterionRuleType.values
              .where((t) => t != CriterionRuleType.legacy)
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(criterionRuleTypeLabel(t)),
                ),
              )
              .toList(),
          onChanged: readOnly
              ? null
              : (t) {
                  if (t == null) return;
                  onChanged(rule.copyWith(type: t));
                },
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._buildParams(context),
      ],
    );
  }

  List<Widget> _buildParams(BuildContext context) {
    switch (rule.type) {
      case CriterionRuleType.prospectField:
        return [
          DropdownButtonFormField<String>(
            initialValue: _fieldValue(rule.field),
            decoration: const InputDecoration(
              labelText: 'Champ prospect',
              isDense: true,
            ),
            items: [
              ...prospectFieldLabels.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
              const DropdownMenuItem(
                value: '__custom__',
                child: Text('Champ personnalisé (CSV)'),
              ),
            ],
            onChanged: readOnly
                ? null
                : (v) {
                    if (v == null) return;
                    onChanged(
                      rule.copyWith(field: v == '__custom__' ? rule.field : v),
                    );
                  },
          ),
          if (rule.field != null &&
              !prospectFieldLabels.containsKey(rule.field))
            TextFormField(
              initialValue: rule.field,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Clé champ personnalisé',
                hintText: 'ex. ca_estime, surface',
                isDense: true,
              ),
              onChanged: (v) => onChanged(rule.copyWith(field: v.trim())),
            ),
        ];
      case CriterionRuleType.boolean:
        return [
          DropdownButtonFormField<String>(
            initialValue: _fieldValue(rule.field),
            decoration: const InputDecoration(
              labelText: 'Champ',
              isDense: true,
            ),
            items: prospectFieldLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: readOnly
                ? null
                : (v) => onChanged(rule.copyWith(field: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Présence du champ'),
            subtitle: rule.presenceOnly
                ? const Text('Points si le champ est rempli')
                : Text('Contient « ${rule.match ?? ''} »'),
            value: rule.presenceOnly,
            onChanged: readOnly
                ? null
                : (v) => onChanged(rule.copyWith(presenceOnly: v)),
          ),
          if (!rule.presenceOnly)
            TextFormField(
              initialValue: rule.match,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Texte à contenir',
                isDense: true,
              ),
              onChanged: (v) => onChanged(rule.copyWith(match: v.trim())),
            ),
        ];
      case CriterionRuleType.threshold:
        return [
          DropdownButtonFormField<String>(
            initialValue: _fieldValue(rule.field),
            decoration: const InputDecoration(
              labelText: 'Champ numérique',
              isDense: true,
            ),
            items: [
              ...prospectFieldLabels.entries
                  .where(
                    (e) =>
                        e.key == 'google_rating' || e.key == 'google_reviews',
                  )
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ),
              const DropdownMenuItem(
                value: '__custom__',
                child: Text('Champ personnalisé (CSV)'),
              ),
            ],
            onChanged: readOnly
                ? null
                : (v) => onChanged(
                    rule.copyWith(field: v == '__custom__' ? rule.field : v),
                  ),
          ),
          if (rule.field != null &&
              !prospectFieldLabels.containsKey(rule.field))
            TextFormField(
              initialValue: rule.field,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Clé champ personnalisé',
                isDense: true,
              ),
              onChanged: (v) => onChanged(rule.copyWith(field: v.trim())),
            ),
          TextFormField(
            initialValue: rule.threshold?.toString(),
            enabled: !readOnly,
            decoration: const InputDecoration(
              labelText: 'Seuil minimum',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                onChanged(rule.copyWith(threshold: double.tryParse(v))),
          ),
        ];
      case CriterionRuleType.keywordMatch:
        return [
          TextFormField(
            initialValue: rule.match,
            enabled: !readOnly,
            decoration: const InputDecoration(
              labelText: 'Mot-clé (nom ou catégorie)',
              isDense: true,
            ),
            onChanged: (v) => onChanged(rule.copyWith(match: v.trim())),
          ),
        ];
      case CriterionRuleType.legacy:
        return [
          Text(
            'Scorer intégré LocalHunter (critères système).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
    }
  }

  String? _fieldValue(String? field) {
    if (field == null) return null;
    if (prospectFieldLabels.containsKey(field)) return field;
    return '__custom__';
  }
}
