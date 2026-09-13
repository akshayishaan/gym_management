import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_gate.dart';
import 'core/navigation.dart';
import 'core/settings/gym_switch_guard.dart';
import 'core/settings/gym_switcher.dart';
import 'core/settings/theme_controller.dart';
import 'layout/shell.dart';
import 'screens/members_screen.dart';
import 'screens/more_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/today_screen.dart';

/// Root widget. Wraps the shell in a `MaterialApp` whose [ThemeData] is a
/// `Provider` derived from the current `GymTheme` (per-gym primary + device
/// brightness), so switching gyms or toggling dark mode re-themes the whole
/// tree without hardcoded colors anywhere.
class GymManagerApp extends ConsumerWidget {
  const GymManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = ref.watch(appThemeProvider);
    final ThemeData darkTheme = ref.watch(appDarkThemeProvider);
    final GymTheme gymTheme = ref.watch(themeControllerProvider);

    final ThemeMode themeMode = switch (gymTheme.brightness) {
      Brightness.dark => ThemeMode.dark,
      Brightness.light => ThemeMode.light,
      null => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Gym Manager',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const AuthGate(child: _RootShell()),
    );
  }
}

/// Holds the selected tab index and renders the matching tab-root body.
///
/// The selection lives in [selectedTabIndexProvider] (not widget-local state)
/// so tab-root screens can deep-link to one another. Drill-in pages (e.g. the
/// member detail screen) are pushed as their own routes and render a
/// `ShellMode.stack` shell.
class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> {
  static const List<String> _titles = <String>[
    'Today',
    'Members',
    'Payments',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = ref.watch(selectedTabIndexProvider);
    return GymSwitchGuard(
      child: AppShell(
        mode: ShellMode.tabRoot,
        title: _titles[selectedIndex],
        selectedIndex: selectedIndex,
        onSelectTab: (int index) =>
            ref.read(selectedTabIndexProvider.notifier).state = index,
        trailing: const GymSwitcher(),
        child: IndexedStack(
          index: selectedIndex,
          children: const <Widget>[
            TodayScreen(),
            MembersScreen(),
            PaymentsScreen(),
            MoreScreen(),
          ],
        ),
      ),
    );
  }
}
