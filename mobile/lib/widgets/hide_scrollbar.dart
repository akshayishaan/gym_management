import 'package:flutter/material.dart';

/// Wraps a scrollable to hide the scrollbar on every platform, mirroring the
/// `.hide-scrollbar` CSS utility (`scrollbar-width: none` + hidden WebKit
/// scrollbar).
///
/// Usage:
/// ```dart
/// HideScrollBar(
///   child: ListView(/* ... */),
/// )
/// ```
///
/// Re-parents the subtree with a copy of the ambient [ScrollBehavior] that has
/// `scrollbars: false`, so no scrollbar is painted regardless of ancestor
/// configuration while every other behavior (physics, drag devices, overscroll
/// glow) is preserved.
class HideScrollBar extends StatelessWidget {
  const HideScrollBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ScrollBehavior behavior =
        ScrollConfiguration.of(context).copyWith(scrollbars: false);
    return ScrollConfiguration(
      behavior: behavior,
      child: child,
    );
  }
}
