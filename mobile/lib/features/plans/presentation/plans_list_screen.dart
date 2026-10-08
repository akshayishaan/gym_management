import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/back_navigation.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/money.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_fab.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_compact_action_button.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_skeleton.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../application/plan_controller.dart';
import '../data/plan_repository.dart';
import '../domain/plan.dart';
import '../domain/plans_response.dart';
import 'plan_form_sheet.dart';

/// Phase 6 — Plans list. Mirrors the Figma `plans_list.png`:
/// back-arrow + count badge + lime "+ New Plan" pill, KPI revenue card,
/// Active/Paused status pills, debounced search bar, list of plan cards
/// (each with name + price + 3-column stats sub-card + feature chips +
/// Edit / Duplicate / Active toggle row).
class PlansListScreen extends ConsumerStatefulWidget {
  const PlansListScreen({super.key});

  @override
  ConsumerState<PlansListScreen> createState() => _PlansListScreenState();
}

class _PlansListScreenState extends ConsumerState<PlansListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _activeStatus; // 'active' | 'inactive' | null = "all"
  Timer? _debounce;

  /// Last loaded list. A filter or search change is a new query, so while it
  /// loads this stays on screen instead of replacing the whole page (which
  /// would also drop the search field and its keyboard).
  PlansResponse? _lastResponse;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _openCreateSheet() async {
    await showLatoFormSheet<void>(
      context: context,
      builder: (_) => const PlanFormSheet(),
    );
  }

  Future<void> _openEditSheet(Plan plan) async {
    await showLatoFormSheet<void>(
      context: context,
      builder: (_) => PlanFormSheet(existingPlan: plan),
    );
  }

  Future<void> _toggleActive(Plan plan, bool next) async {
    try {
      await ref
          .read(planDeactivateControllerProvider.notifier)
          .setActive(plan.id, next);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update plan: $e')));
    }
  }

  /// Opens the New Plan sheet pre-filled from [plan] (named "Name (Copy)").
  Future<void> _duplicatePlan(Plan plan) async {
    await showLatoFormSheet<void>(
      context: context,
      builder: (_) => PlanFormSheet(copyOf: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = PlanListQuery(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      status: _activeStatus,
    );
    final plansAsync = ref.watch(planListProvider(query));
    if (plansAsync.hasValue) _lastResponse = plansAsync.value;
    final shown = plansAsync.valueOrNull ?? _lastResponse;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, kMoreMenuRoute),
        ),
        // The title sits right after the back arrow so the title, the count
        // badge and the "New Plan" button all fit on one line.
        titleSpacing: 0,
        title: shown == null
            ? Text('Membership Plans', style: theme.textTheme.headlineSmall)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Membership Plans',
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: LatoSpacing.sm),
                  _CountBadge(total: shown.counts?.all ?? shown.total),
                ],
              ),
      ),
      floatingActionButton: LatoFab(
        label: 'New Plan',
        onPressed: _openCreateSheet,
      ),
      body: plansAsync.hasError && !plansAsync.hasValue
          ? LatoErrorState(
              message: plansAsync.error is ApiException
                  ? (plansAsync.error as ApiException).message
                  : 'Could not load plans.',
              onRetry: () => ref.invalidate(planListProvider(query)),
            )
          : shown == null
          ? const _PlansPageSkeleton()
          : _PlansListContent(
              response: shown,
              loading: plansAsync.isLoading,
              searchController: _searchController,
              searchQuery: _searchQuery,
              activeStatus: _activeStatus,
              onSearchChanged: _onSearchChanged,
              onClearSearch: _clearSearch,
              onSelectStatus: (s) => setState(() => _activeStatus = s),
              onCreate: _openCreateSheet,
              onEdit: _openEditSheet,
              onDuplicate: _duplicatePlan,
              onToggleActive: _toggleActive,
            ),
    );
  }
}

/// Lime count badge `8` next to the screen title.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: LatoColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LatoColors.primary, width: 1),
      ),
      child: Text(
        formatInrWhole(total),
        style: const TextStyle(
          color: LatoColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Body of the list once data has loaded. Owns the KPI card, status
/// filter row, search bar, and the scrollable list of plan cards.
class _PlansListContent extends StatelessWidget {
  const _PlansListContent({
    required this.response,
    required this.loading,
    required this.searchController,
    required this.searchQuery,
    required this.activeStatus,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSelectStatus,
    required this.onCreate,
    required this.onEdit,
    required this.onDuplicate,
    required this.onToggleActive,
  });

  final PlansResponse response;

  /// A new query is loading: the page stays, the list shows skeleton cards.
  final bool loading;
  final TextEditingController searchController;
  final String searchQuery;
  final String? activeStatus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onSelectStatus;
  final VoidCallback onCreate;
  final void Function(Plan) onEdit;
  final void Function(Plan) onDuplicate;
  final void Function(Plan, bool) onToggleActive;

  /// The plan with the highest activeMembers stat among the current active
  /// set — flagged with the "MOST USED" pill on its card to mirror the
  /// Figma second-card example. Null when there's no clear winner.
  String? _mostUsedPlanId() {
    final active = response.plans
        .where((p) => p.isActive && (p.stats?.activeMembers ?? 0) > 0)
        .toList();
    if (active.length < 2) return null;
    active.sort(
      (a, b) =>
          (b.stats?.activeMembers ?? 0).compareTo(a.stats?.activeMembers ?? 0),
    );
    // Only flag when there's a clear lead (>= 1.2x the next) — avoids
    // surfacing the pill when every plan is essentially tied.
    if (active.length >= 2 &&
        active.first.stats!.activeMembers <
            (active[1].stats!.activeMembers * 1.2)) {
      return null;
    }
    return active.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final counts = response.counts;
    final allCount = counts?.all ?? response.total;
    final activeCount = counts?.active ?? 0;
    final inactiveCount = counts?.inactive ?? 0;
    final plans = response.plans;
    final isFiltering = (activeStatus != null) || searchQuery.isNotEmpty;
    final mostUsedId = _mostUsedPlanId();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LatoSpacing.xl,
            LatoSpacing.sm,
            LatoSpacing.xl,
            LatoSpacing.md,
          ),
          child: _RevenueKpiCard(summary: response.summary),
        ),
        // Status filter pills
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.xl),
            children: [
              _StatusPill(
                label: 'All ($allCount)',
                selected: activeStatus == null,
                onTap: () => onSelectStatus(null),
              ),
              const SizedBox(width: LatoSpacing.sm),
              _StatusPill(
                label: 'Active ($activeCount)',
                selected: activeStatus == 'active',
                onTap: () => onSelectStatus('active'),
              ),
              const SizedBox(width: LatoSpacing.sm),
              _StatusPill(
                label: 'Paused ($inactiveCount)',
                selected: activeStatus == 'inactive',
                onTap: () => onSelectStatus('inactive'),
              ),
            ],
          ),
        ),
        const SizedBox(height: LatoSpacing.md),
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LatoSpacing.xl,
            0,
            LatoSpacing.xl,
            LatoSpacing.md,
          ),
          child: _SearchBar(
            controller: searchController,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
            hasQuery: searchQuery.isNotEmpty,
          ),
        ),
        // List body
        Expanded(
          child: loading
              ? const _PlansSkeletonList()
              : plans.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(LatoSpacing.lg),
                    child: LatoEmptyState(
                      icon: Icons.card_membership_outlined,
                      title: isFiltering ? 'No plans match' : 'No plans yet',
                      body: isFiltering ? 'Try a different search or filter.' : 'Create your first plan to start selling memberships.',
                      actionLabel: 'Create Plan',
                      onAction: onCreate,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    LatoSpacing.xl,
                    0,
                    LatoSpacing.xl,
                    LatoSpacing.fabClearance,
                  ),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: LatoSpacing.md),
                      child: _PlanCard(
                        plan: plan,
                        isMostUsed: plan.id == mostUsedId,
                        onTap: () => context.push('/plans/${plan.id}'),
                        onEdit: () => onEdit(plan),
                        onDuplicate: () => onDuplicate(plan),
                        onToggleActive: (next) => onToggleActive(plan, next),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// KPI card: "YEAR-TO-DATE PLAN REVENUE" + $X.XX + Sales Volume / Active
/// Members row. Mirrors the Figma revenue card but uses the PlansSummary
/// roll-up (revenueAtSaleYtd, salesYtd, activeMembers).
class _RevenueKpiCard extends StatelessWidget {
  const _RevenueKpiCard({this.summary});
  final PlansSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revenue = summary?.revenueAtSaleYtd ?? 0;
    final sales = summary?.salesYtd ?? 0;
    final active = summary?.activeMembers ?? 0;

    return LatoCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YEAR-TO-DATE PLAN REVENUE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: LatoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${formatInrWhole(revenue.truncate())}',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  '.${((revenue - revenue.truncate()).abs() * 100).round().toString().padLeft(2, '0')}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _KpiSubStat(
                  label: 'Sales Volume',
                  value: '${formatInrWhole(sales)} sold',
                  valueColor: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: LatoSpacing.lg),
              Expanded(
                child: _KpiSubStat(
                  label: 'Active Members',
                  value: '${formatInrWhole(active)} active',
                  valueColor: LatoColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiSubStat extends StatelessWidget {
  const _KpiSubStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Filter pill used in the status row.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
            child: LatoStatusChip(
              label: label,
              tone: selected ? LatoChipTone.primary : LatoChipTone.neutral,
            ),
          ),
        ),
      ),
    );
  }
}

/// Search bar with leading search icon, trailing clear-X when populated.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasQuery,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search plans',
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: LatoColors.textSecondaryDark,
        ),
        suffixIcon: hasQuery
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: LatoColors.textSecondaryDark,
                ),
                onPressed: onClear,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LatoSpacing.md,
          vertical: 0,
        ),
      ),
    );
  }
}

/// One plan row: name + price header, 3-column stats sub-card, feature
/// chips, and Edit / Duplicate / Active toggle row. Mirrors the Figma
/// `plans_list.png` card exactly.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isMostUsed,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onToggleActive,
  });

  final Plan plan;
  final bool isMostUsed;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = plan.stats;

    return Semantics(
      button: true,
      label: 'Plan ${plan.name}',
      child: LatoCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.lg,
          LatoSpacing.lg,
          LatoSpacing.lg,
          LatoSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: name + (optional) MOST USED pill + price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          plan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMostUsed) ...[
                        const SizedBox(width: LatoSpacing.sm),
                        const LatoStatusChip(
                          label: 'MOST USED',
                          tone: LatoChipTone.primary,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: LatoSpacing.sm),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: plan.formattedPrice,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: LatoColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '  / ${plan.durationDays} days',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: LatoSpacing.md),
            // 3-column stats sub-card
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LatoSpacing.md,
                vertical: LatoSpacing.md,
              ),
              decoration: BoxDecoration(
                color: LatoColors.bgDark,
                borderRadius: BorderRadius.circular(LatoRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      rightInset: true,
                      label: 'Members',
                      value: formatInrWhole(stats?.activeMembers ?? 0),
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _StatCell(
                      leftInset: true,
                      label: 'YTD Sales',
                      value: formatInrWhole(stats?.salesYtd ?? 0),
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _StatCell(
                      leftInset: true,
                      label: 'YTD Revenue',
                      value: _formatRevenue(stats?.revenueAtSaleYtd ?? 0),
                      valueColor: LatoColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Feature chips
            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: LatoSpacing.md),
              Wrap(
                spacing: LatoSpacing.sm,
                runSpacing: LatoSpacing.sm,
                children: [
                  for (final f in plan.features)
                    LatoStatusChip(label: f, tone: LatoChipTone.neutral),
                ],
              ),
            ],
            const SizedBox(height: LatoSpacing.md),
            // Bottom action row
            Row(
              children: [
                LatoCompactActionButton(
                  label: 'Edit',
                  color: LatoColors.textPrimaryDark,
                  borderColor: LatoColors.borderStrongDark,
                  onTap: onEdit,
                ),
                const SizedBox(width: LatoSpacing.sm),
                LatoCompactActionButton(
                  label: 'Duplicate',
                  color: LatoColors.textPrimaryDark,
                  borderColor: LatoColors.borderStrongDark,
                  onTap: onDuplicate,
                ),
                const Spacer(),
                Text('Active', style: theme.textTheme.labelLarge),
                const SizedBox(width: LatoSpacing.sm),
                Switch.adaptive(
                  value: plan.isActive,
                  onChanged: onToggleActive,
                  activeThumbColor: LatoColors.primary,
                  activeTrackColor: LatoColors.primary.withValues(alpha: 0.35),
                  inactiveThumbColor: LatoColors.textSecondaryDark,
                  inactiveTrackColor: LatoColors.textSecondaryDark.withValues(
                    alpha: 0.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Whole-rupee amount for the stats sub-card, e.g. `₹1,42,400`.
String _formatRevenue(double value) => '₹${formatInrWhole(value.truncate())}';

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.leftInset = false,
    this.rightInset = false,
  });
  final String label;
  final String value;
  final Color? valueColor;

  /// Space after the divider so the text does not touch it.
  final bool leftInset;

  /// Space before the divider on the first cell.
  final bool rightInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: leftInset ? LatoSpacing.md : 0,
        right: rightInset ? LatoSpacing.sm : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: LatoColors.borderDark);
  }
}

/// First-load placeholder for the whole page: revenue card, filter pills,
/// search bar and the card list, so the layout is already in place when the
/// data arrives.
class _PlansPageSkeleton extends StatelessWidget {
  const _PlansPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        key: const Key('plans-page-skeleton'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              LatoSpacing.xl,
              LatoSpacing.sm,
              LatoSpacing.xl,
              LatoSpacing.md,
            ),
            child: LatoCard(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LatoSkeletonBlock(width: 140, height: 12),
                  SizedBox(height: LatoSpacing.sm),
                  LatoSkeletonBlock(width: 180, height: 44),
                  SizedBox(height: LatoSpacing.lg),
                  Row(
                    children: [
                      LatoSkeletonBlock(width: 96, height: 32),
                      SizedBox(width: LatoSpacing.lg),
                      LatoSkeletonBlock(width: 96, height: 32),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.xl),
              children: const [
                LatoSkeletonBlock(width: 72, height: 36, radius: LatoRadius.pill),
                SizedBox(width: LatoSpacing.sm),
                LatoSkeletonBlock(width: 88, height: 36, radius: LatoRadius.pill),
                SizedBox(width: LatoSpacing.sm),
                LatoSkeletonBlock(width: 88, height: 36, radius: LatoRadius.pill),
              ],
            ),
          ),
          const SizedBox(height: LatoSpacing.md),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              LatoSpacing.xl,
              0,
              LatoSpacing.xl,
              LatoSpacing.md,
            ),
            child: LatoSkeletonBlock(height: 48, radius: LatoRadius.md),
          ),
          const Expanded(child: _PlansSkeletonList()),
        ],
      ),
    );
  }
}

/// Placeholder list shown while a new filter or search loads. Same card
/// padding and block heights as [_PlanCard], so the layout does not jump.
class _PlansSkeletonList extends StatelessWidget {
  const _PlansSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('plans-skeleton'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        LatoSpacing.xl,
        0,
        LatoSpacing.xl,
        LatoSpacing.fabClearance,
      ),
      children: const [
        _PlanCardSkeleton(),
        SizedBox(height: LatoSpacing.md),
        _PlanCardSkeleton(),
      ],
    );
  }
}

class _PlanCardSkeleton extends StatelessWidget {
  const _PlanCardSkeleton();

  static Widget _block(double? width, double height, [double radius = 8]) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: LatoColors.surfaceRaisedDark,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LatoCard(
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.lg,
          LatoSpacing.lg,
          LatoSpacing.lg,
          LatoSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_block(120, 22), _block(110, 28)],
            ),
            const SizedBox(height: LatoSpacing.md),
            Container(
              height: 66,
              decoration: BoxDecoration(
                color: LatoColors.bgDark,
                borderRadius: BorderRadius.circular(LatoRadius.md),
              ),
            ),
            const SizedBox(height: LatoSpacing.md),
            Row(
              children: [
                _block(96, 28, LatoRadius.pill),
                const SizedBox(width: LatoSpacing.sm),
                _block(120, 28, LatoRadius.pill),
              ],
            ),
            const SizedBox(height: LatoSpacing.md),
            Row(
              children: [
                _block(64, 36, LatoRadius.md),
                const SizedBox(width: LatoSpacing.sm),
                _block(96, 36, LatoRadius.md),
                const Spacer(),
                _block(52, 30, LatoRadius.pill),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
