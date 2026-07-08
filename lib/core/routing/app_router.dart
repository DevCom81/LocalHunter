import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'route_names.dart';
import 'app_shell.dart';
import 'go_router_refresh.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/settings_screen.dart';
import '../../features/campaigns/presentation/screens/campaigns_list_screen.dart';
import '../../features/campaigns/presentation/screens/campaign_detail_screen.dart';
import '../../features/campaigns/presentation/screens/campaign_create_screen.dart';
import '../../features/prospects/presentation/screens/dashboard_screen.dart';
import '../../features/prospects/presentation/screens/import_csv_screen.dart';
import '../../features/prospects/presentation/screens/prospect_detail_screen.dart';
import '../../features/prospects/presentation/screens/crm_screen.dart';
import '../../features/ai_analysis/presentation/screens/ai_analysis_screen.dart';
import '../../features/export/presentation/screens/export_screen.dart';
import '../../features/scoring/domain/entities/scoring_grid.dart';
import '../../features/scoring/presentation/screens/scoring_grids_list_screen.dart';
import '../../features/scoring/presentation/screens/scoring_grid_editor_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../config/supabase_config.dart';
import '../network/supabase_client_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refresh = GoRouterRefreshStream(
    client?.auth.onAuthStateChange ?? const Stream.empty(),
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: RouteNames.dashboard,
    redirect: (context, state) {
      if (!SupabaseConfig.isConfigured) return null;
      final isLoggedIn = client?.auth.currentSession != null;
      final isAuthRoute =
          state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.signUp;
      if (!isLoggedIn && !isAuthRoute) return RouteNames.login;
      if (isLoggedIn && isAuthRoute) return RouteNames.dashboard;

      final path = state.uri.path;
      if (path.startsWith(RouteNames.scoringSettings)) {
        final suffix = path.substring(RouteNames.scoringSettings.length);
        return suffix.isEmpty
            ? RouteNames.scoring
            : '${RouteNames.scoring}$suffix';
      }
      return null;
    },
    routes: [
      GoRoute(path: RouteNames.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: RouteNames.signUp, builder: (_, _) => const SignUpScreen()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.campaigns,
            builder: (_, _) => const CampaignsListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, _) => const CampaignCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => CampaignDetailScreen(
                  campaignId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'import',
                    builder: (_, state) => ImportCsvScreen(
                      campaignId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'prospects',
                    builder: (_, state) =>
                        CrmScreen(campaignId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'export',
                    builder: (_, state) =>
                        ExportScreen(campaignId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.scoring,
            builder: (_, _) => const ScoringGridsListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, state) => ScoringGridEditorScreen(
                  isNew: true,
                  duplicateFromId: state.uri.queryParameters['duplicate'],
                  initialGrid: state.extra as ScoringGrid?,
                ),
              ),
              GoRoute(
                path: ':gridId',
                builder: (_, state) => ScoringGridEditorScreen(
                  gridId: state.pathParameters['gridId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/prospects/:id',
            builder: (_, state) =>
                ProspectDetailScreen(prospectId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'ai',
                builder: (_, state) =>
                    AiAnalysisScreen(prospectId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.subscription,
            builder: (_, _) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: RouteNames.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
