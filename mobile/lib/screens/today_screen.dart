import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';

/// Placeholder for the Today (dashboard) tab — Issue 15 fills in the real
/// metric cards, quick actions and recent-payments list. Renders the design
/// system to prove the theme + shell work end-to-end.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppScreen(
        children: <Widget>[
          AppSectionLabel('Overview'),
          const SizedBox(height: 12),
          AppSurface(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: t.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Today\'s dashboard is scaffolded for Issue 15. Recent '
                  'payments, expiring memberships and quick actions land here.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: t.muted.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
