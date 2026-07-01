import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return AppScaffold(
      title: 'Paramètres',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (SupabaseConfig.isConfigured && user != null) ...[
            Text('Connecté : ${user.email ?? user.id}'),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go(RouteNames.login);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ] else
            const Text('Mode démo — Supabase non configuré'),
        ],
      ),
    );
  }
}
