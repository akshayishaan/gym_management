// Phase 6 — Plan detail. The Figma inventory for plans only includes
// list + create + edit surfaces; this screen is the *richer* view opened
// when the user taps a plan card (the per-card "Edit" button stays a
// shortcut into Track B's `PlanFormSheet` in edit mode). It is built from
// the data the list already returns — there is no `GET /plans/:id` on the
// backend yet, so we look the plan up inside `planListProvider` and show
// a "Plan not found" empty state if the id is missing from the first
// page (e.g. opened from a deep link or after a delete).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/money.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../application/plan_controller.dart';
import '../data/plan_repository.dart';
import '../domain/plan.dart';
import '../domain/plans_response.dart';
import 'plan_form_sheet.dart';

/// A fixed list query that pulls the first page of plans for the active
/// gym. The detail screen needs the full plan (including stats), so we
/// read the same provider the list screen uses and find the row in
/// memory. With a default `limit: 100` the page comfortably covers the
/// realistic plan count per gym.
const _kAllPlansQuery = PlanListQuery(limit: 100);

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  Future<void> _openEditSheet(Plan plan) async {
    await showLatoFormSheet<void>(
      context: context,
      builder: (_) => PlanFormSheet(existingPlan: plan),
    );
  }

  Future<void> _confirmAndDeactivate(Plan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LatoColors.surfaceDark,
        title: Text('Deactivate ${plan.name}?'),
        content: const Text(
          'Existing members keep their access. The plan will no longer be '
          'available for new purchases.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: LatoColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Deactivate',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(planDeactivateControllerProvider.notifier)
          .setActive(plan.id, false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${plan.name} deactivated')));
      // Pop back to the list; the underlying provider invalidation will
      // refresh the row in the list view automatically.
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Could not deactivate plan.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _reactivate(Plan plan) async {
    try {
      await ref
          .read(planDeactivateControllerProvider.notifier)
          .setActive(plan.id, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${plan.name} reactivated')));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Could not reactivate plan.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the active gym so tenant switches re-fetch the list.
    final asyncPlans = ref.watch(planListProvider(_kAllPlansQuery));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('Plan Details'),
        actions: [
          asyncPlans.maybeWhen(
            data: (result) {
              final plan = _findPlan(result, widget.id);
              if (plan == null) return const SizedBox(width: 48);
              return IconButton(
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: LatoColors.primary,
                  size: 22,
                ),
                onPressed: () => _openEditSheet(plan),
              );
            },
            orElse: () => const SizedBox(width: 48),
          ),
        ],
      ),
      body: asyncPlans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorBody(
          message: err is ApiException ? err.message : null,
          onRetry: () => ref.invalidate(planListProvider),
        ),
        data: (result) {
          final plan = _findPlan(result, widget.id);
          if (plan == null) {
            return LatoEmptyState(
              icon: Icons.fitness_center_outlined,
              title: 'Plan not found',
              body: 'It may have been removed.',
              actionLabel: 'Back to plans',
              onAction: () => context.go('/plans'),
            );
          }
          return _DetailBody(
            plan: plan,
            onDeactivate: () => _confirmAndDeactivate(plan),
            onReactivate: () => _reactivate(plan),
          );
        },
      ),
    );
  }

  Plan? _findPlan(PlansResponse result, String id) {
    for (final p in result.plans) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.plan,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final Plan plan;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            LatoSpacing.xl,
            LatoSpacing.lg,
            LatoSpacing.xl,
            LatoSpacing.md,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _IdentityCard(plan: plan),
              const SizedBox(height: LatoSpacing.lg),
              _StatsCard(plan: plan),
              if (plan.features.isNotEmpty) ...[
                const SizedBox(height: LatoSpacing.lg),
                _FeaturesCard(features: plan.features),
              ],
              const SizedBox(height: LatoSpacing.lg),
              _DatesRow(plan: plan),
              const SizedBox(height: LatoSpacing.xxl),
              _BottomActions(
                plan: plan,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
              ),
              const SizedBox(height: LatoSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Identity card: plan name, price + duration, and status chip.
/// Matches the Figma plan card header: title left, status chip right,
/// price large with duration sub-label.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              _StatusChip(isActive: plan.isActive),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.formattedPrice,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LatoColors.textPrimaryDark,
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              Flexible(
                child: Text(
                  '/ ${plan.durationDays} day${plan.durationDays == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: LatoColors.textSecondaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: LatoSpacing.md),
            Text(plan.description!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return LatoStatusChip(
      label: isActive ? 'ACTIVE' : 'PAUSED',
      tone: isActive ? LatoChipTone.primary : LatoChipTone.neutral,
    );
  }
}

/// Three-column stats card: Members, YTD Sales, YTD Revenue. YTD Revenue
/// is tinted lime per the Figma. Stats default to 0 when the backend
/// doesn't return them, so a brand-new plan renders zeros instead of
/// crashing.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final stats = plan.stats;
    final activeMembers = stats?.activeMembers ?? 0;
    final salesYtd = stats?.salesYtd ?? 0;
    final revenueYtd = stats?.revenueAtSaleYtd ?? 0.0;

    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Active members',
              value: formatInrWhole(activeMembers),
              valueColor: LatoColors.textPrimaryDark,
            ),
          ),
          Container(width: 1, height: 40, color: LatoColors.borderDark),
          Expanded(
            child: _StatColumn(
              label: 'YTD Sales',
              value: formatInrWhole(salesYtd),
              valueColor: LatoColors.textPrimaryDark,
            ),
          ),
          Container(width: 1, height: 40, color: LatoColors.borderDark),
          Expanded(
            child: _StatColumn(
              label: 'YTD Revenue',
              value: _formatCurrency(revenueYtd),
              valueColor: LatoColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double v) => '₹${formatInrWhole(v.truncate())}';
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: LatoColors.textSecondaryDark,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature chips (`24/7 Access`, `Recovery Lab`, etc.), neutral like the list
/// card. When the plan has no features the parent omits the whole card.
class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard({required this.features});
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LatoSpacing.md),
          Wrap(
            spacing: LatoSpacing.sm,
            runSpacing: LatoSpacing.sm,
            children: [
              for (final f in features)
                LatoStatusChip(label: f, tone: LatoChipTone.neutral),
            ],
          ),
        ],
      ),
    );
  }
}

/// Created / updated date row. Renders small muted text below the
/// features card. Missing dates render as em-dashes.
class _DatesRow extends StatelessWidget {
  const _DatesRow({required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: LatoColors.textSecondaryDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text('Created ${_formatDate(plan.createdAt)}', style: style),
          ),
          const SizedBox(width: LatoSpacing.md),
          Expanded(
            child: Text(
              'Updated ${_formatDate(plan.updatedAt)}',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('d MMM y').format(dt.toLocal());
  }
}

/// Deactivate (red outline) for an active plan, Reactivate (lime outline) for
/// a paused one. Editing is the pencil in the app bar.
class _BottomActions extends ConsumerWidget {
  const _BottomActions({
    required this.plan,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final Plan plan;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(planDeactivateControllerProvider).loading;
    final active = plan.isActive;
    final color = active ? LatoColors.error : LatoColors.primary;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1),
          minimumSize: const Size.fromHeight(LatoSizes.button),
        ),
        onPressed: loading ? null : (active ? onDeactivate : onReactivate),
        child: loading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Text(
                active ? 'Deactivate' : 'Reactivate',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LatoSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: LatoColors.textSecondaryDark,
            ),
            const SizedBox(height: LatoSpacing.md),
            Text(
              message ?? 'Could not load plans.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LatoSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
