import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/grid_config.dart';
import '../../domain/entities/scoring_grid.dart';
import '../utils/criterion_key_generator.dart';
import 'grid_config_editor.dart';
import 'scoring_criterion_tile.dart';

class ScoringGridEditorBody extends StatefulWidget {
  const ScoringGridEditorBody({
    super.key,
    required this.grid,
    required this.saving,
    required this.onSave,
    this.onDelete,
    this.onDuplicate,
  });

  final ScoringGrid grid;
  final bool saving;
  final ValueChanged<ScoringGrid> onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  @override
  State<ScoringGridEditorBody> createState() => _ScoringGridEditorBodyState();
}

class _ScoringGridEditorBodyState extends State<ScoringGridEditorBody> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late List<ScoringCriterion> _criteria;
  late GridExclusionConfig _exclusionConfig;
  late GridRecommendationConfig _recommendationConfig;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.grid.name);
    _descCtrl = TextEditingController(text: widget.grid.description);
    _criteria = List.of(widget.grid.criteria);
    _exclusionConfig = widget.grid.exclusionConfig;
    _recommendationConfig = widget.grid.recommendationConfig;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  int get _componentTotal => _criteria
      .where((c) => c.kind == CriterionKind.component && c.isActive)
      .fold(0, (sum, c) => sum + c.maxPoints);

  void _updateCriterion(int index, ScoringCriterion updated) {
    setState(() => _criteria[index] = updated);
  }

  void _removeCriterion(int index) {
    setState(() => _criteria.removeAt(index));
  }

  void _addCriterion() {
    final label = 'Nouveau critère ${_criteria.length + 1}';
    setState(() {
      _criteria.add(
        ScoringCriterion(
          key: generateCriterionKey(label, _criteria),
          label: label,
          kind: CriterionKind.component,
          maxPoints: 10,
          rule: const CriterionRule(
            type: CriterionRuleType.prospectField,
            field: 'phone',
            presenceOnly: true,
          ),
        ),
      );
    });
  }

  ScoringGrid _buildGrid() {
    return widget.grid.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? widget.grid.name : _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      criteria: _criteria,
      exclusionConfig: _exclusionConfig,
      recommendationConfig: _recommendationConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridForConfig = widget.grid.copyWith(
      criteria: _criteria,
      exclusionConfig: _exclusionConfig,
      recommendationConfig: _recommendationConfig,
    );

    return AppScaffold(
      title: widget.grid.isTemplate
          ? '${widget.grid.name} (modèle)'
          : 'Éditer la grille',
      body: ListView(
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom de la grille'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optionnelle)',
              hintText: 'Ex. : acquisition pharmacies pour groupe immobilier',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Critères (total composants : $_componentTotal pts)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Chaque critère est calculé automatiquement via sa règle. '
            'Les champs personnalisés CSV sont disponibles pour les seuils et présence.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(_criteria.length, (i) {
            return ScoringCriterionTile(
              criterion: _criteria[i],
              canRemove: _criteria.length > 1,
              onChanged: (updated) => _updateCriterion(i, updated),
              onRemove: () => _removeCriterion(i),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addCriterion,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un critère'),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridConfigEditor(
            grid: gridForConfig,
            onExclusionChanged: (c) => setState(() => _exclusionConfig = c),
            onRecommendationChanged: (c) =>
                setState(() => _recommendationConfig = c),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.onDuplicate != null)
            FilledButton.icon(
              onPressed: widget.onDuplicate,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Dupliquer cette grille'),
            ),
          FilledButton(
            onPressed: widget.saving ? null : () => widget.onSave(_buildGrid()),
            child: widget.saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer la grille'),
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.highPriority),
              label: const Text(
                'Supprimer la grille',
                style: TextStyle(color: AppColors.highPriority),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
