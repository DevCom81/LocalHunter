import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../providers/bodacc_providers.dart';

/// Enrichissement BODACC manuel (campagne) — indépendant de la source discovery.
class EnrichBodaccButton extends ConsumerStatefulWidget {
  const EnrichBodaccButton({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<EnrichBodaccButton> createState() => _EnrichBodaccButtonState();
}

class _EnrichBodaccButtonState extends ConsumerState<EnrichBodaccButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final n = await runBodaccEnrichment(
        ref,
        campaignId: widget.campaignId,
        forceRefresh: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n > 0
                ? 'BODACC : $n prospect(s) enrichi(s).'
                : 'BODACC : aucun éligible '
                    '(exclu, déjà à jour, ou identifiant légal insuffisant).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BODACC impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const SizedBox.shrink();
    }
    return ActionChip(
      avatar: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.campaign_outlined, size: 18),
      label: const Text('Enrichir BODACC'),
      onPressed: _busy ? null : _run,
    );
  }
}
