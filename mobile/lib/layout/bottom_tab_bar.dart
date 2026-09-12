import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// A single tab in the floating bottom dock.
class DockTab {
  const DockTab({
    required this.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// The four fixed tabs, matching the web `BottomTabBar` (Home/Members/
/// Payments/More with House/Users/Receipt/LayoutGrid glyphs).
const List<DockTab> kDockTabs = <DockTab>[
  DockTab(
    key: 'today',
    label: 'Today',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
  ),
  DockTab(
    key: 'members',
    label: 'Members',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
  ),
  DockTab(
    key: 'payments',
    label: 'Payments',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
  ),
  DockTab(
    key: 'more',
    label: 'More',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view,
  ),
];

/// Floating dock reproducing the web `.BottomTabBar`:
///
/// - Fixed floating dock `inset-x-3`, height ~4.35rem, max-width 27rem,
///   centered, radius 1.6rem, border `primary-foreground @10%`, background
///   `dock @95%`, strong shadow + blur, bottom offset
///   `0.5rem + safe-area-inset-bottom`.
/// - Four tabs, each 3.5rem tall flex-1 column, radius 1.15rem, ~20px icon,
///   10px bold label; active = primary + thicker stroke, inactive =
///   dock-foreground @55%.
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final MediaQueryData media = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 8 + media.padding.bottom, // 0.5rem + safe-area bottom
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 432), // 27rem
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25.6), // 1.6rem
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 69.6, // ~4.35rem
                  decoration: BoxDecoration(
                    color: withOpacity(t.dock.value, 0.95),
                    borderRadius: BorderRadius.circular(25.6),
                    border: Border.all(
                      color: withOpacity(t.primary.foreground, 0.10),
                    ),
                    // `shadow-2xl shadow-foreground/20` → strong, diffuse shadow.
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: withOpacity(t.foreground, 0.20),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, // px-1.5
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < kDockTabs.length; i++)
                        _DockTabButton(
                          tab: kDockTabs[i],
                          tokens: t,
                          selected: i == selectedIndex,
                          onTap: () => onSelect(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockTabButton extends StatelessWidget {
  const _DockTabButton({
    required this.tab,
    required this.tokens,
    required this.selected,
    required this.onTap,
  });

  final DockTab tab;
  final ThemeTokens tokens;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected
        ? tokens.primary.value
        : withOpacity(tokens.dock.foreground, 0.55);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.4), // 1.15rem
          child: Container(
            height: 56, // 3.5rem
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.4),
              color: selected
                  ? withOpacity(tokens.primary.value, 0.12)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 20,
                  color: foreground,
                ),
                const SizedBox(height: 2),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
