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
      appBar: AppBar(toolbarHeight: 56, title: const Text('Operations')),
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
                subtitle: 'Membership plans and pricing',
                route: '/plans',
                isFirst: true,
              ),
              _NavRow(
                icon: Icons.bar_chart_outlined,
                title: 'Reports',
                subtitle: 'Revenue and member reports',
                route: '/reports',
              ),
              _NavRow(
                icon: Icons.history,
                title: 'Activity',
                subtitle: 'Staff actions and audit trail',
                route: '/activity',
              ),
              _NavRow(
                icon: Icons.business_outlined,
                title: 'My Gyms',
                subtitle: 'Switch, add or edit gyms',
                route: '/gyms',
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
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
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
          color: LatoColors.textSecondaryDark,
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
    this.isFirst = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: LatoSpacing.md,
            vertical: LatoSpacing.md,
          ),
          decoration: BoxDecoration(
            border: isFirst
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
        color: LatoColors.bgDark,
        borderRadius: BorderRadius.circular(LatoRadius.sm),
        border: Border.all(color: LatoColors.borderStrongDark, width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: LatoColors.textSecondaryDark),
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
    const unselectedBorder = LatoColors.borderStrongDark;

    return Material(
      color: LatoColors.surfaceDark,
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
                const Positioned(top: 4, right: 4, child: _SelectedDot()),
              SizedBox(
                width: double.infinity,
                child: Column(
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

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LatoColors.surfaceDark,
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: LatoColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sign out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: LatoSizes.button,
      child: OutlinedButton.icon(
        onPressed: () => _confirm(context, ref),
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
