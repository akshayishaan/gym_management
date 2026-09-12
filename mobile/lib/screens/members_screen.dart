import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';

/// Placeholder for the Members tab — Issue 15 wires search, status filters
/// and the member card list.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppScreen(
        children: <Widget>[
          const AppSectionLabel('Members'),
          const SizedBox(height: 12),
          AppSurface(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Member search, status filters and the member card list arrive '
              'with Issues 15.',
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
