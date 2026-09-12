import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      home: const _RootShell(),
    );
  }
}

/// Holds the selected tab index and renders the matching tab-root body.
///
/// Tab-root screens (Today/Members/Payments/More) are placeholders for
/// Issues 15-18; drill-in routing (StackHeader pages) is exercised by the
/// shell's `ShellMode.stack` but no real drill-in target exists yet.
class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>[
    'Today',
    'Members',
    'Payments',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      mode: ShellMode.tabRoot,
      title: _titles[_selectedIndex],
      selectedIndex: _selectedIndex,
      onSelectTab: (int index) => setState(() => _selectedIndex = index),
      child: IndexedStack(
        index: _selectedIndex,
        children: const <Widget>[
          TodayScreen(),
          MembersScreen(),
          PaymentsScreen(),
          MoreScreen(),
        ],
      ),
    );
  }
}
