import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'route_names.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppSpacing.mobileBreakpoint;
        if (!isWide) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: child,
            bottomNavigationBar: const PremiumMobileNav(),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              const PremiumSideNav(),
              Expanded(
                child: ColoredBox(color: AppColors.background, child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PremiumSideNav extends StatelessWidget {
  const PremiumSideNav({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      width: AppSpacing.sidebarWidth,
      color: AppColors.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'LocalHunter',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
          ),
          _SideNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: location.startsWith(RouteNames.dashboard),
            onTap: () => context.go(RouteNames.dashboard),
          ),
          _SideNavItem(
            icon: Icons.campaign_outlined,
            label: 'Campagnes',
            selected: location.startsWith(RouteNames.campaigns),
            onTap: () => context.go(RouteNames.campaigns),
          ),
          _SideNavItem(
            icon: Icons.grid_view_outlined,
            label: 'Scoring',
            selected: location.startsWith(RouteNames.scoring),
            onTap: () => context.go(RouteNames.scoring),
          ),
          _SideNavItem(
            icon: Icons.workspace_premium_outlined,
            label: 'Abonnement',
            selected: location.startsWith(RouteNames.subscription),
            onTap: () => context.go(RouteNames.subscription),
          ),
          _SideNavItem(
            icon: Icons.settings_outlined,
            label: 'Paramètres',
            selected: location.startsWith(RouteNames.settings),
            onTap: () => context.go(RouteNames.settings),
          ),
        ],
      ),
    );
  }
}

class PremiumMobileNav extends StatelessWidget {
  const PremiumMobileNav({super.key});

  int _indexFor(String location) {
    if (location.startsWith(RouteNames.campaigns)) return 1;
    if (location.startsWith(RouteNames.scoring)) return 2;
    if (location.startsWith(RouteNames.subscription)) return 3;
    if (location.startsWith(RouteNames.settings)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return NavigationBar(
      backgroundColor: AppColors.primaryDark,
      indicatorColor: AppColors.primaryLight,
      selectedIndex: _indexFor(location),
      onDestinationSelected: (index) {
        final path = switch (index) {
          1 => RouteNames.campaigns,
          2 => RouteNames.scoring,
          3 => RouteNames.subscription,
          4 => RouteNames.settings,
          _ => RouteNames.dashboard,
        };
        context.go(path);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined, color: AppColors.textOnDark),
          selectedIcon: Icon(Icons.dashboard, color: AppColors.navActive),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.campaign_outlined, color: AppColors.textOnDark),
          selectedIcon: Icon(Icons.campaign, color: AppColors.navActive),
          label: 'Campagnes',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined, color: AppColors.textOnDark),
          selectedIcon: Icon(Icons.grid_view, color: AppColors.navActive),
          label: 'Scoring',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.workspace_premium_outlined,
            color: AppColors.textOnDark,
          ),
          selectedIcon: Icon(
            Icons.workspace_premium,
            color: AppColors.navActive,
          ),
          label: 'Abonnement',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined, color: AppColors.textOnDark),
          selectedIcon: Icon(Icons.settings, color: AppColors.navActive),
          label: 'Paramètres',
        ),
      ],
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navActive : AppColors.textOnDark;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.25),
      onTap: onTap,
    );
  }
}
