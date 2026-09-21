import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/weight_suggestion.dart';
import '../providers/scoring_providers.dart';
import '../providers/weight_suggestion_providers.dart';

class WeightSuggestionsScreen extends ConsumerStatefulWidget {
  const WeightSuggestionsScreen({super.key, required this.gridId});

  final String gridId;

  @override
  ConsumerState<WeightSuggestionsScreen> createState() =>
      _WeightSuggestionsScreenState();
}

class _WeightSuggestionsScreenState
    extends ConsumerState<WeightSuggestionsScreen> {
  bool _analyzing = false;
  bool _busy = false;

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    try {
      final result =
          await regenerateWeightSuggestions(ref, widget.gridId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isEmpty
                ? 'Pas assez de feedback CRM contrasté pour suggérer.'
                : '${result.length} suggestion(s) proposée(s).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analyse impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _accept(WeightSuggestion suggestion) async {
    setState(() => _busy = true);
    try {
      await acceptWeightSuggestion(ref, suggestion);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '« ${suggestion.criterionLabel} » : '
            '${suggestion.currentMaxPoints} → ${suggestion.suggestedMaxPoints} pts. '
            'Prospects re-scorés.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Acceptation impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ignore(WeightSuggestion suggestion) async {
    setState(() => _busy = true);
    try {
      await ignoreWeightSuggestion(ref, suggestion);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ignorer impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridAsync = ref.watch(scoringGridByIdProvider(widget.gridId));
    final suggestionsAsync =
        ref.watch(pendingWeightSuggestionsProvider(widget.gridId));

    final title = gridAsync.maybeWhen(
      data: (g) => g != null ? 'Suggestions — ${g.name}' : 'Suggestions CRM',
      orElse: () => 'Suggestions CRM',
    );

    return AppScaffold(
      title: title,
      actions: [
        IconButton(
          tooltip: 'Analyser le feedback CRM',
          onPressed: _analyzing || _busy ? null : _analyze,
          icon: _analyzing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.analytics_outlined),
        ),
      ],
      body: suggestionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Aucune suggestion en attente.\n'
                    'Analysez le feedback CRM des campagnes liées à cette grille '
                    '(min. 3 retenus et 3 écartés).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _analyzing || _busy ? null : _analyze,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analyser le feedback'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final s = suggestions[i];
              return _SuggestionCard(
                suggestion: s,
                enabled: !_busy && !_analyzing,
                onAccept: () => _accept(s),
                onIgnore: () => _ignore(s),
              );
            },
          );
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.enabled,
    required this.onAccept,
    required this.onIgnore,
  });

  final WeightSuggestion suggestion;
  final bool enabled;
  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final delta = suggestion.delta;
    final deltaLabel = delta > 0 ? '+$delta' : '$delta';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.criterionLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${suggestion.currentMaxPoints} → ${suggestion.suggestedMaxPoints} pts ($deltaLabel)',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              suggestion.rationale,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: enabled ? onIgnore : null,
                    child: const Text('Ignorer'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: enabled ? onAccept : null,
                    child: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
