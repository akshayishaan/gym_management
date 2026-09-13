import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_controller.dart';
import '../core/auth/auth_state.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';
import '../widgets/avatar.dart';
import 'activity_screen.dart';
import 'gyms_screen.dart';
import 'plans_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// The More tab: workspace owner card + drill-in entries for Plans, Reports,
/// Activity, Gyms, and Settings. (Issue 18.)
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final AuthUser? user = ref.watch(authControllerProvider).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppScreen(
        children: <Widget>[
          const AppSectionLabel('More'),
          const SizedBox(height: 12),
          _OwnerCard(user: user, t: t),
          const SizedBox(height: 24),
          const AppSectionLabel('Manage'),
          const SizedBox(height: 12),
          _ManageTile(
            icon: Icons.fitness_center,
            tone: withOpacity(t.primary.value, 0.10),
            iconColor: t.primary.value,
            label: 'Plans',
            description: 'Pricing & access',
            t: t,
            wide: true,
            onTap: () => _push(context, const PlansScreen()),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _ManageTile(
                  icon: Icons.bar_chart,
                  tone: withOpacity(t.success.value, 0.10),
                  iconColor: t.success.value,
                  label: 'Reports',
                  description: 'Growth & revenue',
                  t: t,
                  onTap: () => _push(context, const ReportsScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ManageTile(
                  icon: Icons.list_alt_outlined,
                  tone: withOpacity(t.warning.value, 0.15),
                  iconColor: t.warning.value,
                  label: 'Activity',
                  description: 'Team timeline',
                  t: t,
                  onTap: () => _push(context, const ActivityScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _ManageTile(
                  icon: Icons.apartment,
                  tone: withOpacity(t.accent.value, 0.10),
                  iconColor: t.accent.foreground,
                  label: 'My Gyms',
                  description: 'Locations',
                  t: t,
                  onTap: () => _push(context, const GymsScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ManageTile(
                  icon: Icons.settings_outlined,
                  tone: withOpacity(t.muted.value, 0.60),
                  iconColor: t.muted.foreground,
                  label: 'Settings',
                  description: 'Account & theme',
                  t: t,
                  onTap: () => _push(context, const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppSurface(
            color: withOpacity(t.destructive.value, 0.10),
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.logout, color: t.destructive.value),
                const SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: t.destructive.value,
                    fontWeight: FontWeight.w600,
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

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.user, required this.t});

  final AuthUser? user;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.foreground,
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: withOpacity(t.primary.value, 0.5),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: withOpacity(t.primary.value, 0.5),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Avatar(
                  name: user?.name ?? '',
                  size: 56,
                  background: withOpacity(t.background, 0.10),
                ),
                const SizedBox(height: 14),
                Text(
                  'WORKSPACE OWNER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: withOpacity(t.background, 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? '—',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: t.background,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: withOpacity(t.background, 0.6),
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

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.tone,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.t,
    required this.onTap,
    this.wide = false,
  });

  final IconData icon;
  final Color tone;
  final Color iconColor;
  final String label;
  final String description;
  final ThemeTokens t;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          if (wide)
            const SizedBox(width: 12)
          else
            const Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: t.muted.foreground, size: 18),
        ],
      ),
    );
  }
}
