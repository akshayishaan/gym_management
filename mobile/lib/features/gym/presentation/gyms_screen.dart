import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/back_navigation.dart';
import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_fab.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../application/active_gym_controller.dart';
import '../domain/gym.dart';
import 'gym_form_sheet.dart';
import 'gym_switcher_sheet.dart';

/// My Gyms: every gym this account manages. Tap a gym to switch to it, use
/// the pencil to edit or delete it, and the + button to add another.
class GymsScreen extends ConsumerWidget {
  const GymsScreen({super.key});

  static const double _avatar = 44;

  Future<void> _switch(BuildContext context, WidgetRef ref, Gym gym) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(selectedGymIdProvider.notifier).select(gym.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Switched to ${gym.name}')));
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not switch: ${e.message}')),
      );
    }
  }

  Future<void> _add(BuildContext context) async {
    await showLatoFormSheet<GymFormResult>(
      context: context,
      builder: (_) => const GymFormSheet(),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Gym gym) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showLatoFormSheet<GymFormResult>(
      context: context,
      builder: (_) => GymFormSheet(existing: gym),
    );
    if (result != GymFormResult.deleted) return;

    // The gym no longer exists: drop it from the account and move to
    // another one (or to gym creation when it was the last).
    final next = await ref
        .read(authControllerProvider.notifier)
        .onGymDeleted(gym.id);
    final selected = ref.read(selectedGymIdProvider.notifier);
    if (next == null) {
      await selected.clear();
    } else {
      await selected.select(next);
    }
    ref.invalidate(userGymsProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${gym.name} was deleted')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gymsAsync = ref.watch(userGymsProvider);
    final selectedId = ref.watch(selectedGymIdProvider);

    return Scaffold(
      backgroundColor: LatoColors.bgDark,
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => popOrGo(context, kMoreMenuRoute),
        ),
        title: Text('My Gyms', style: theme.textTheme.headlineSmall),
      ),
      floatingActionButton: LatoFab(
        label: 'Add Gym',
        onPressed: () => _add(context),
      ),
      body: gymsAsync.when(
        skipLoadingOnReload: true,
        loading: () => const _ListSkeleton(),
        error: (err, _) => LatoErrorState(
          message: err is ApiException ? err.message : 'Could not load gyms.',
          onRetry: () => ref.invalidate(userGymsProvider),
        ),
        data: (gyms) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            LatoSpacing.xl,
            LatoSpacing.sm,
            LatoSpacing.xl,
            LatoSpacing.fabClearance,
          ),
          itemCount: gyms.length,
          separatorBuilder: (_, _) => const SizedBox(height: LatoSpacing.md),
          itemBuilder: (_, i) {
            final gym = gyms[i];
            final isActive = gym.id == selectedId;
            return _GymCard(
              gym: gym,
              isActive: isActive,
              onTap: isActive ? null : () => _switch(context, ref, gym),
              onEdit: () => _edit(context, ref, gym),
            );
          },
        ),
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({
    required this.gym,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
  });

  final Gym gym;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = gym.name.trim().isEmpty
        ? 'G'
        : gym.name.trim().substring(0, 1).toUpperCase();
    final address = gym.address?.trim() ?? '';
    return Semantics(
      container: true,
      selected: isActive,
      child: LatoCard(
        onTap: onTap,
        borderColor: isActive ? LatoColors.primary : null,
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.lg,
          LatoSpacing.md,
          LatoSpacing.xs,
          LatoSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: GymsScreen._avatar,
              height: GymsScreen._avatar,
              decoration: BoxDecoration(
                color: LatoColors.tint(LatoColors.primary),
                borderRadius: BorderRadius.circular(LatoRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: LatoColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: LatoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: LatoSpacing.xxs),
                    Text(
                      address,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isActive) ...[
                    const SizedBox(height: LatoSpacing.sm),
                    const LatoStatusChip(
                      label: 'Active',
                      tone: LatoChipTone.primary,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit ${gym.name}',
              constraints: const BoxConstraints(
                minWidth: LatoSizes.button,
                minHeight: LatoSizes.button,
              ),
              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: LatoColors.textSecondaryDark,
              ),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double w, double h, double r) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return ExcludeSemantics(
      child: ListView.separated(
        key: const Key('gyms-skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.xl,
          LatoSpacing.sm,
          LatoSpacing.xl,
          0,
        ),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: LatoSpacing.md),
        itemBuilder: (_, _) => LatoCard(
          child: SizedBox(
            height: GymsScreen._avatar,
            child: Row(
              children: [
                block(GymsScreen._avatar, GymsScreen._avatar, LatoRadius.md),
                const SizedBox(width: LatoSpacing.md),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(120, 14, LatoRadius.sm),
                    const SizedBox(height: LatoSpacing.sm),
                    block(180, 12, LatoRadius.sm),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
