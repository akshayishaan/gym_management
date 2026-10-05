import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/staff.dart';
import '../../gym/application/active_gym_controller.dart';
import '../../settings/application/theme_controller.dart';

/// Phase 9 Track B — More menu. Replaces the Phase 6 placeholder
/// (`OperationsScreen` → `PlansListScreen`). The "Operations" tab in
/// [RootShell] now opens this menu; Plans, Reports, Activity, and
/// My Gyms are listed as navigation rows inside it.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authControllerProvider).staff;
    final activeGymAsync = ref.watch(activeGymProvider);
    final gymName = activeGymAsync.maybeWhen(
      data: (gym) => gym?.name,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('Operations'),
        actions: const [_NotificationButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.xl,
          0,
          LatoSpacing.xl,
          96,
        ),
        children: [
          _ProfileCard(staff: staff, gymName: gymName),
          const SizedBox(height: LatoSpacing.lg),
          const _SectionEyebrow('FACILITY OPERATIONS'),
          const SizedBox(height: LatoSpacing.sm),
          const _NavCard(
            children: [
              _NavRow(
                icon: Icons.workspace_premium_outlined,
                title: 'Plans',
                subtitle: 'Membership tiers, pricing & billing cycles',
                route: '/plans',
              ),
              _NavRow(
                icon: Icons.bar_chart_outlined,
                title: 'Reports',
                subtitle: 'Financial analytics, attendance & retention metrics',
                route: '/reports',
              ),
              _NavRow(
                icon: Icons.history,
                title: 'Activity',
                subtitle: 'Live check-in feed, staff logs & audit trail',
                route: '/activity',
              ),
              _NavRow(
                icon: Icons.business_outlined,
                title: 'My Gyms',
                subtitle: 'Switch active location & manage facility branches',
                route: '/gym/picker',
              ),
              _NavRow(
                icon: Icons.settings_outlined,
                title: 'Gym Settings',
                subtitle: 'Name, address, currency, timezone & reminders',
                route: '/settings',
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.lg),
          const _SectionEyebrow('APPEARANCE & DISPLAY'),
          const SizedBox(height: LatoSpacing.sm),
          const _AppearanceSelector(),
          const SizedBox(height: LatoSpacing.lg),
          const _SignOutButton(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar
// ---------------------------------------------------------------------------

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications — coming soon')),
            );
          },
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.notifications_outlined,
              size: 20,
              color: LatoColors.textSecondaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.staff, required this.gymName});
  final Staff? staff;
  final String? gymName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = staff?.name ?? 'Signed in';
    final email = staff?.email ?? (gymName ?? '—');
    final initials = _initials(staff?.name);

    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Row(
        children: [
          _InitialsTile(initials: initials),
          const SizedBox(width: LatoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    final out = (first + last).toUpperCase();
    return out.isEmpty ? '?' : out;
  }
}

class _InitialsTile extends StatelessWidget {
  const _InitialsTile({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: LatoColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(LatoRadius.sm),
        border: Border.all(
          color: LatoColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: LatoColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section eyebrow
// ---------------------------------------------------------------------------

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LatoSpacing.sm),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC4C9AC),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.55,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation rows (Plans / Reports / Activity / My Gyms)
// ---------------------------------------------------------------------------

class _NavCard extends StatelessWidget {
  const _NavCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(route),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: LatoSpacing.md,
            vertical: LatoSpacing.md,
          ),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    top: BorderSide(color: LatoColors.borderDark, width: 1),
                  ),
          ),
          child: Row(
            children: [
              _IconTile(icon: icon),
              const SizedBox(width: LatoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: LatoColors.textPrimaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LatoColors.textSecondaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: LatoColors.textSecondaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF262A31),
        borderRadius: BorderRadius.circular(LatoRadius.sm),
        border: Border.all(
          color: const Color(0xFF31353C),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 18,
        color: LatoColors.textSecondaryDark,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance selector
// ---------------------------------------------------------------------------

class _AppearanceSelector extends ConsumerWidget {
  const _AppearanceSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    return Row(
      children: [
        Expanded(
          child: _AppearancePill(
            icon: Icons.dark_mode_outlined,
            label: 'Dark',
            secondary: 'Obsidian',
            selected: mode == AppThemeMode.dark,
            onTap: () => ref
                .read(themeControllerProvider.notifier)
                .setMode(AppThemeMode.dark),
          ),
        ),
        const SizedBox(width: LatoSpacing.sm),
        Expanded(
          child: _AppearancePill(
            icon: Icons.light_mode_outlined,
            label: 'Light',
            secondary: 'Standard',
            selected: mode == AppThemeMode.light,
            onTap: () => ref
                .read(themeControllerProvider.notifier)
                .setMode(AppThemeMode.light),
          ),
        ),
        const SizedBox(width: LatoSpacing.sm),
        Expanded(
          child: _AppearancePill(
            icon: Icons.brightness_auto_outlined,
            label: 'System',
            secondary: 'Sync OS',
            selected: mode == AppThemeMode.system,
            onTap: () => ref
                .read(themeControllerProvider.notifier)
                .setMode(AppThemeMode.system),
          ),
        ),
      ],
    );
  }
}

class _AppearancePill extends StatelessWidget {
  const _AppearancePill({
    required this.icon,
    required this.label,
    required this.secondary,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String secondary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedBorder = LatoColors.primary;
    const unselectedBorder = Color(0xFF31353C);

    return Material(
      color: const Color(0xFF1C2026),
      borderRadius: BorderRadius.circular(LatoRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LatoRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: LatoSpacing.md,
            horizontal: LatoSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LatoRadius.md),
            border: Border.all(
              color: selected ? selectedBorder : unselectedBorder,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              if (selected)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: _SelectedDot(),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? LatoColors.primary
                        : LatoColors.textPrimaryDark,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? LatoColors.primary
                          : LatoColors.textPrimaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: const TextStyle(
                      color: LatoColors.textSecondaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDot extends StatelessWidget {
  const _SelectedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: LatoColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign out
// ---------------------------------------------------------------------------

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () =>
            ref.read(authControllerProvider.notifier).signOut(),
        icon: const Icon(Icons.logout, size: 18, color: LatoColors.error),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            color: LatoColors.error,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: LatoColors.error,
          side: const BorderSide(color: LatoColors.error, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LatoRadius.md),
          ),
        ),
      ),
    );
  }
}
