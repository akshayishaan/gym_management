import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hosts the bottom navigation bar for the 4-tab RepiX shell.
/// Matches the Figma: Dashboard / Members / Payments / Operations.
class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.child});
  final Widget child;

  static const _tabs = <_NavTab>[
    _NavTab(
      label: 'Dashboard',
      route: '/home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
    ),
    _NavTab(
      label: 'Members',
      route: '/members',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    _NavTab(
      label: 'Payments',
      route: '/payments',
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments,
    ),
    _NavTab(
      label: 'Operations',
      route: '/operations',
      icon: Icons.tune,
      activeIcon: Icons.tune,
    ),
  ];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => location.startsWith(t.route));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          context.go(_tabs[i].route);
        },
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.activeIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.route,
    required this.icon,
    required this.activeIcon,
  });
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;
}
