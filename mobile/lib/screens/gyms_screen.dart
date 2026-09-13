import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_providers.dart';
import '../core/auth/auth_controller.dart';
import '../core/settings/gym_settings_controller.dart';
import '../data/api_helpers.dart';
import '../data/gym_providers.dart';
import '../layout/shell.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_surface.dart';
import '../widgets/fab.dart';
import '../widgets/gym_avatar.dart';
import '../widgets/gym_form_sheet.dart';
import '../widgets/hide_scrollbar.dart';

/// The "My Gyms" drill-in screen: lists every gym the user can access, lets
/// admins create/edit/delete gyms, and switches the active selection. Ported
/// from the web `app/dashboard/gyms/page.tsx`.
class GymsScreen extends ConsumerStatefulWidget {
  const GymsScreen({super.key});

  @override
  ConsumerState<GymsScreen> createState() => _GymsScreenState();
}

class _GymsScreenState extends ConsumerState<GymsScreen> {
  void _create() async {
    final GymResponse? created = await GymFormSheet.show(context);
    if (created == null) return;
    if (!mounted) return;
    try {
      ref.invalidate(gymsProvider);
      final List<GymResponse> gyms = await ref.read(gymsProvider.future);
      await ref.read(gymSettingsControllerProvider.notifier).reconcileGyms(gyms);
      await ref.read(gymSettingsControllerProvider.notifier).switchGym(created.id);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Could not switch to the new gym', isError: true);
      }
    }
  }

  void _edit(GymResponse gym) async {
    await GymFormSheet.show(context, gym: gym);
    if (!mounted) return;
    ref.invalidate(gymsProvider);
    final List<GymResponse> gyms = await ref.read(gymsProvider.future);
    await ref.read(gymSettingsControllerProvider.notifier).reconcileGyms(gyms);
  }

  Future<void> _delete(GymResponse gym) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeTokens dt =
            Theme.of(dialogContext).extension<AppThemeTokens>()!.tokens;
        return AlertDialog(
          title: Text('Delete "${gym.name}"?'),
          content: const Text(
            'This will permanently delete this gym and all its members, plans, '
            'payments, and activity logs. This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete Gym',
                style: TextStyle(color: dt.destructive.value),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final dio = ref.read(dioProvider);
    try {
      await deleteJson<SuccessResponse>(
        dio,
        '/gyms/${gym.id}',
        fromJson: SuccessResponse.fromJson,
      );
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
      return;
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Could not delete gym', isError: true);
      }
      return;
    }
    if (!mounted) return;
    showAppSnackBar(context, 'Gym deleted');
    ref.invalidate(gymsProvider);
    try {
      final List<GymResponse> gyms = await ref.read(gymsProvider.future);
      await ref.read(gymSettingsControllerProvider.notifier).reconcileGyms(gyms);
    } catch (_) {
      // Refetch/reconcile failure after a successful delete is non-fatal:
      // the list surface will render its error state with a retry affordance.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    final AsyncValue<List<GymResponse>> gymsAsync = ref.watch(gymsProvider);
    final String? selectedGymId = ref.watch(selectedGymIdProvider);
    final bool isAdmin = ref.watch(authControllerProvider).user?.role == 'admin';

    return AppShell(
      mode: ShellMode.stack,
      title: 'My Gyms',
      selectedIndex: 3,
      onSelectTab: (_) {},
      onBack: () => Navigator.of(context).maybePop(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HideScrollBar(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 20, bottom: 96),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const AppSectionLabel('Your locations'),
                              Text(
                                '${gymsAsync.valueOrNull?.length ?? 0} total',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: t.muted.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...gymsAsync.when(
                          data: (List<GymResponse> gyms) => _buildList(
                            t,
                            isAdmin,
                            selectedGymId,
                            gyms,
                          ),
                          loading: () => _buildLoading(t),
                          error: (Object e, StackTrace st) => _buildError(t),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isAdmin)
                Positioned(
                  right: 20,
                  bottom: 16,
                  child: AppFab(onPressed: _create),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList(
    ThemeTokens t,
    bool isAdmin,
    String? selectedGymId,
    List<GymResponse> gyms,
  ) {
    if (gyms.isEmpty) {
      return <Widget>[
        AppSurface(
          borderRadius: BorderRadius.circular(32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: withOpacity(t.primary.value, 0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.apartment, size: 28, color: t.primary.value),
              ),
              const SizedBox(height: 16),
              Text(
                'No gyms yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: t.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your first gym to get started',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: t.muted.foreground),
              ),
              if (isAdmin) ...<Widget>[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary.value,
                    foregroundColor: t.primary.foreground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(t.radius),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create gym'),
                ),
              ],
            ],
          ),
        ),
      ];
    }

    return <Widget>[
      for (final GymResponse gym in gyms)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _GymCard(
            gym: gym,
            isCurrent: gym.id == selectedGymId,
            isAdmin: isAdmin,
            onSwitch: () =>
                ref.read(gymSettingsControllerProvider.notifier).switchGym(gym.id),
            onEdit: () => _edit(gym),
            onDelete: () => _delete(gym),
          ),
        ),
    ];
  }

  List<Widget> _buildLoading(ThemeTokens t) {
    return <Widget>[
      for (int i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 168,
            decoration: BoxDecoration(
              color: withOpacity(t.foreground, 0.08),
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildError(ThemeTokens t) {
    return <Widget>[
      AppSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(Icons.error_outline, size: 32, color: t.destructive.value),
            const SizedBox(height: 12),
            Text(
              'Gyms could not load',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: t.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please try again.',
              style: TextStyle(fontSize: 13, color: t.muted.foreground),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.invalidate(gymsProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ];
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({
    required this.gym,
    required this.isCurrent,
    required this.isAdmin,
    required this.onSwitch,
    required this.onEdit,
    required this.onDelete,
  });

  final GymResponse gym;
  final bool isCurrent;
  final bool isAdmin;
  final VoidCallback onSwitch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    final Widget card = AppSurface(
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GymAvatar(
                name: gym.name,
                logo: gym.logo,
                primaryColor: gym.primaryColor,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      gym.name,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: t.foreground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _Badge(
                          label: gym.isActive ? 'Active' : 'Inactive',
                          color: gym.isActive
                              ? t.success.value
                              : t.muted.foreground,
                        ),
                        if (isCurrent)
                          _Badge(
                            label: 'Current',
                            color: t.primary.value,
                            showCheck: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((gym.address != null && gym.address!.isNotEmpty) ||
              (gym.phone != null && gym.phone!.isNotEmpty) ||
              (gym.email != null && gym.email!.isNotEmpty)) ...<Widget>[
            const SizedBox(height: 14),
            if (gym.address != null && gym.address!.isNotEmpty)
              _contactRow(Icons.map_outlined, gym.address!, t),
            if (gym.phone != null && gym.phone!.isNotEmpty)
              _contactRow(Icons.phone_outlined, gym.phone!, t),
            if (gym.email != null && gym.email!.isNotEmpty)
              _contactRow(Icons.mail_outline, gym.email!, t),
          ],
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: withOpacity(t.border, 0.58),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: isCurrent ? null : onSwitch,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary.value,
                    foregroundColor: t.primary.foreground,
                    disabledBackgroundColor: withOpacity(t.primary.value, 0.5),
                    disabledForegroundColor: t.primary.foreground,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(t.radius),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(isCurrent ? 'Current Gym' : 'Switch to Gym'),
                ),
              ),
              if (isAdmin) ...<Widget>[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 20, color: t.foreground),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: t.destructive.value,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (!isCurrent) return card;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: withOpacity(t.primary.value, 0.6), width: 2),
        borderRadius: BorderRadius.circular(32),
      ),
      child: card,
    );
  }

  Widget _contactRow(IconData icon, String value, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: t.muted.foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: t.muted.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.showCheck = false,
  });

  final String label;
  final Color color;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: withOpacity(color, 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showCheck) ...<Widget>[
            Icon(Icons.check, size: 12, color: color),
            const SizedBox(width: 4),
          ] else ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
