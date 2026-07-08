import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../domain/entities/campaign.dart';
import '../providers/campaign_providers.dart';

/// Bouton de suppression d'une campagne avec confirmation explicite.
/// La suppression est destructive : prospects, scores et historiques liés
/// sont supprimés en cascade côté base.
class DeleteCampaignButton extends ConsumerWidget {
  const DeleteCampaignButton({
    super.key,
    required this.campaign,
    required this.prospectCount,
  });

  final Campaign campaign;
  final int prospectCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Supprimer la campagne',
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _confirmAndDelete(context, ref),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la campagne ?'),
        content: Text(
          '« ${campaign.name} » sera définitivement supprimée, '
          'ainsi que ses $prospectCount prospect(s), leurs scores '
          'et leur historique. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(campaignsProvider.notifier).delete(campaign.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campagne « ${campaign.name} » supprimée')),
        );
        context.go(RouteNames.campaigns);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la suppression : $e')),
        );
      }
    }
  }
}
