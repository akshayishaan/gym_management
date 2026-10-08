import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/spacing.dart';
import '../application/active_gym_controller.dart';
import '../data/gym_repository.dart';
import '../domain/gym.dart';

/// The staff's gyms. Watched by the dashboard's gym pill so the list is
/// already loaded when the switcher opens, and refetched when the active gym
/// changes (a newly created gym is auto-selected).
final userGymsProvider = FutureProvider<List<Gym>>((ref) {
  ref.watch(selectedGymIdProvider);
  return ref.watch(gymRepositoryProvider).listGyms();
});

/// Opens the gym switcher as a modal sheet. Uses the root navigator so the
/// sheet and its scrim cover the bottom navigation bar.
Future<void> showGymSwitcherSheet(BuildContext context) {
  return showLatoSheet<void>(
    context: context,
    builder: (_) => const GymSwitcherSheet(),
  );
}

/// Content-height sheet capped at 70% of the screen; the list scrolls inside
/// the cap. Loading, error and empty states are all one row tall (the height
/// of a real gym row), and height changes animate, so the sheet does not jump
/// when data arrives.
class GymSwitcherSheet extends ConsumerWidget {
  const GymSwitcherSheet({super.key});

  static const double _rowContentHeight = 44;

  Future<void> _select(BuildContext context, WidgetRef ref, Gym gym) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(selectedGymIdProvider.notifier).select(gym.id);
      navigator.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not switch: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedGymIdProvider);
    final gymsAsync = ref.watch(userGymsProvider);

    final Widget body = gymsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const _GymRowSkeleton(),
      error: (err, _) => _GymRowMessage(
        message: err is ApiException ? err.message : 'Could not load gyms.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(userGymsProvider),
      ),
      data: (gyms) {
        if (gyms.isEmpty) {
          return const _GymRowMessage(message: 'No gyms available');
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: gyms.length,
          separatorBuilder: (_, _) => const SizedBox(height: LatoSpacing.md),
          itemBuilder: (_, i) {
            final gym = gyms[i];
            final isActive = gym.id == selectedId;
            return _GymRow(
              gym: gym,
              isActive: isActive,
              onTap: isActive
                  ? () => Navigator.of(context).pop()
                  : () => _select(context, ref, gym),
            );
          },
        );
      },
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LatoSpacing.xl,
              0,
              LatoSpacing.xl,
              LatoSpacing.md,
            ),
            child: Text('Switch gym', style: theme.textTheme.headlineSmall),
          ),
          Flexible(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  0,
                  LatoSpacing.xl,
                  LatoSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymRow extends StatelessWidget {
  const _GymRow({
    required this.gym,
    required this.isActive,
    required this.onTap,
  });

  final Gym gym;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = gym.name.trim().isEmpty
        ? 'G'
        : gym.name.trim().substring(0, 1).toUpperCase();
    return Semantics(
      button: true,
      selected: isActive,
      label: 'Switch to ${gym.name}',
      child: LatoCard(
        onTap: onTap,
        borderColor: isActive ? LatoColors.primary : null,
        child: Row(
          children: [
            Container(
              width: GymSwitcherSheet._rowContentHeight,
              height: GymSwitcherSheet._rowContentHeight,
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
                  if (gym.address != null && gym.address!.isNotEmpty) ...[
                    const SizedBox(height: LatoSpacing.xxs),
                    Text(
                      gym.address!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle, color: LatoColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Placeholder with the same card, padding and content height as [_GymRow].
class _GymRowSkeleton extends StatelessWidget {
  const _GymRowSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double width, double height, double radius) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return ExcludeSemantics(
      child: LatoCard(
        child: SizedBox(
          height: GymSwitcherSheet._rowContentHeight,
          child: Row(
            children: [
              block(
                GymSwitcherSheet._rowContentHeight,
                GymSwitcherSheet._rowContentHeight,
                LatoRadius.md,
              ),
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
    );
  }
}

/// One-row message (error or empty) with the same card and content height as
/// [_GymRow].
class _GymRowMessage extends StatelessWidget {
  const _GymRowMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LatoCard(
      child: SizedBox(
        height: GymSwitcherSheet._rowContentHeight,
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}
