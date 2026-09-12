import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';

/// Placeholder for the More tab — Issue 18 wires gyms, plans, reports,
/// settings and the activity log.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppScreen(
        children: <Widget>[
          const AppSectionLabel('More'),
          const SizedBox(height: 12),
          AppSurface(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Plans, reports, gym management, settings and the activity log '
              'arrive with Issues 17-18.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: t.muted.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
