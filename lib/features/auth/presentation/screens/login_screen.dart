import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/biometric_auth_service.dart';
import '../../data/biometric_credential_store.dart';
import '../../data/remember_me_store.dart';
import '../../domain/auth_platform.dart';
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
  final _biometricAuth = BiometricAuthService();
  final _biometricStore = BiometricCredentialStore();

  bool _rememberMe = true;
  bool _prefsLoaded = false;
  bool _biometricAvailable = false;
  bool _biometricEnrolled = false;
  bool _biometricPromptStarted = false;

  @override
  void initState() {
    super.initState();
    _loadLoginPrefs();
  }

  Future<void> _loadLoginPrefs() async {
    final remember = await RememberMeStore.loadRememberMe();
    final email = await RememberMeStore.loadRememberedEmail();
    var biometricAvailable = false;
    var biometricEnrolled = false;
    if (isMobileBiometricPlatform && SupabaseConfig.isConfigured) {
      biometricAvailable = await _biometricAuth.isAvailable();
      biometricEnrolled =
          biometricAvailable && await _biometricStore.isEnabled();
    }
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (email != null) {
        _emailController.text = email;
        ref.read(authControllerProvider.notifier).setEmail(email);
      }
      _biometricAvailable = biometricAvailable;
      _biometricEnrolled = biometricEnrolled;
      _prefsLoaded = true;
    });
    if (biometricEnrolled && !_biometricPromptStarted) {
      _biometricPromptStarted = true;
      // Auto-propose biométrie une fois l'écran prêt.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _signInWithBiometrics();
      });
    }
  }

  Future<void> _signInWithBiometrics() async {
    final authCtrl = ref.read(authControllerProvider.notifier);
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading) return;

    final okBio = await _biometricAuth.authenticate(
      reason: 'Déverrouillez LocalHunter',
    );
    if (!okBio || !mounted) return;

    final creds = await _biometricStore.read();
    if (creds == null) {
      if (!mounted) return;
      setState(() => _biometricEnrolled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Identifiants biométriques introuvables. Connectez-vous une fois.',
          ),
        ),
      );
      return;
    }

    _emailController.text = creds.email;
    final ok = await authCtrl.signInWithStoredCredentials(
      email: creds.email,
      password: creds.password,
    );
    if (ok && mounted) {
      context.go(RouteNames.dashboard);
    }
  }

  Future<void> _offerBiometricEnrollment({
    required String email,
    required String password,
  }) async {
    if (!isMobileBiometricPlatform || !_biometricAvailable) return;
    if (await _biometricStore.isEnabled()) return;
    if (!mounted) return;

    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connexion biométrique'),
        content: const Text(
          'Activer Face ID / empreinte pour vous connecter '
          'sans retaper votre mot de passe ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
    if (enable != true || !mounted) return;

    final confirmed = await _biometricAuth.authenticate(
      reason: 'Confirmez pour enregistrer la connexion biométrique',
    );
    if (!confirmed || !mounted) return;

    await _biometricStore.save(email: email, password: password);
    if (!mounted) return;
    setState(() => _biometricEnrolled = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connexion biométrique activée')),
    );
  }

  Future<void> _onPasswordSignIn() async {
    final authCtrl = ref.read(authControllerProvider.notifier);
    final email = _emailController.text;
    final password = _passwordController.text;
    authCtrl.setEmail(email);
    authCtrl.setPassword(password);
    final ok = await authCtrl.signIn(rememberMe: _rememberMe);
    if (!ok || !mounted) return;
    await _offerBiometricEnrollment(email: email, password: password);
    if (mounted) context.go(RouteNames.dashboard);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

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
                    onChanged: (v) =>
                        ref.read(authControllerProvider.notifier).setEmail(v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthPasswordField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    onChanged: (v) => ref
                        .read(authControllerProvider.notifier)
                        .setPassword(v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Se souvenir de moi'),
                    value: _rememberMe,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: !_prefsLoaded
                        ? null
                        : (value) {
                            setState(() => _rememberMe = value ?? true);
                          },
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
                    onPressed: auth.isLoading ? null : _onPasswordSignIn,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Se connecter'),
                  ),
                  if (_prefsLoaded &&
                      _biometricEnrolled &&
                      SupabaseConfig.isConfigured) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed:
                          auth.isLoading ? null : _signInWithBiometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Connexion biométrique'),
                    ),
                  ],
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
