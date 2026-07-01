import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/route_names.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/supabase_config_banner.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'LocalHunter',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Prospection locale pour agences web',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SupabaseConfigBanner(),
                  if (!SupabaseConfig.isConfigured)
                    const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    onChanged: authCtrl.setEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthPasswordField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    onChanged: authCtrl.setPassword,
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(auth.error!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (auth.info != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(auth.info!, style: const TextStyle(color: Colors.green)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            authCtrl.setEmail(_emailController.text);
                            authCtrl.setPassword(_passwordController.text);
                            final ok = await authCtrl.signIn();
                            if (ok && context.mounted) {
                              context.go(RouteNames.dashboard);
                            }
                          },
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Se connecter'),
                  ),
                  if (SupabaseConfig.isConfigured) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.go(RouteNames.signUp),
                      child: const Text('Créer un compte'),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: () => context.go(RouteNames.dashboard),
                      child: const Text('Mode démo (sans Supabase)'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
