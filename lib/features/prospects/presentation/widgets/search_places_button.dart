import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../providers/places_search_providers.dart';

class SearchPlacesButton extends ConsumerWidget {
  const SearchPlacesButton({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseConfig.isConfigured) {
      return const Chip(label: Text('Recherche Places : Supabase requis'));
    }

    final searchState = ref.watch(placesSearchProvider);
    final loading = searchState.isLoading;

    return ActionChip(
      avatar: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.search, size: 18),
      label: const Text('Rechercher (Google Places)'),
      onPressed: loading
          ? null
          : () async {
              try {
                final result = await ref
                    .read(placesSearchProvider.notifier)
                    .searchForCampaign(campaignId);
                if (!context.mounted) return;
                final cache = result.fromCache ? ' (cache)' : '';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${result.count} prospects importés$cache',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e')),
                );
              }
            },
    );
  }
}
