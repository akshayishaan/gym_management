import 'package:flutter/material.dart';

import '../widgets/app_canvas.dart';
import 'bottom_tab_bar.dart';
import 'stack_header.dart';
import 'top_app_bar.dart';

/// The two navigational modes of the shell.
enum ShellMode {
  /// Tab-root: `TopAppBar` (brand + title) + scrollable content + floating
  /// `BottomTabBar` dock.
  tabRoot,

  /// Drill-in: edge-to-edge content that provides its own [StackHeader].
  stack,
}

/// The application shell that composes [AppCanvas], the tab-root chrome
/// ([TopAppBar] + [BottomTabBar]) or a drill-in layout (edge-to-edge with a
/// [StackHeader]), around a given screen body.
///
/// This is the visual/navigation host; the Riverpod-backed index/indexed-stack
/// selection lives in `App` so the shell stays presentational.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.mode,
    required this.title,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.child,
    this.onBack,
    this.actions,
    this.trailing,
  });

  final ShellMode mode;
  final String title;
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final Widget child;

  /// Drill-in only: back callback (defaults to `Navigator.pop` in the header).
  final VoidCallback? onBack;

  /// Drill-in only: trailing actions for the header.
  final List<Widget>? actions;

  /// Tab-root only: replaces the GymPicker placeholder in the top bar.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCanvas(
      child: switch (mode) {
        ShellMode.tabRoot => _TabRootShell(this),
        ShellMode.stack => _StackShell(this),
      },
    );
  }
}

class _TabRootShell extends StatelessWidget {
  const _TabRootShell(this.shell);

  final AppShell shell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TopAppBar(title: shell.title, trailing: shell.trailing),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448), // ~28rem
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20), // px-5
                child: shell.child,
              ),
            ),
          ),
        ),
        BottomTabBar(
          selectedIndex: shell.selectedIndex,
          onSelect: shell.onSelectTab,
        ),
      ],
    );
  }
}

class _StackShell extends StatelessWidget {
  const _StackShell(this.shell);

  final AppShell shell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        StackHeader(
          title: shell.title,
          onBack: shell.onBack,
          actions: shell.actions,
        ),
        Expanded(child: shell.child),
      ],
    );
  }
}
