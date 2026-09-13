import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';
import 'plans_screen.dart';
import 'reports_screen.dart';

/// The More tab: drill-in entries for Plans and Reports. (Issue 18 adds gyms,
/// settings and the activity log.)
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppScreen(
        children: <Widget>[
          const AppSectionLabel('More'),
          const SizedBox(height: 12),
          AppSurface(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: <Widget>[
                _MoreTile(
                  icon: Icons.description_outlined,
                  label: 'Plans',
                  tokens: t,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PlansScreen(),
                    ),
                  ),
                ),
                _MoreTile(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  tokens: t,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportsScreen(),
                    ),
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

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.tokens,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.muted.value,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: t.foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.foreground,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: t.muted.foreground),
          ],
        ),
      ),
    );
  }
}
