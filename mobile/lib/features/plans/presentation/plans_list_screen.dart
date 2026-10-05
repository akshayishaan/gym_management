import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_loading.dart';
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LatoColors.surfaceDark,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (sheetCtx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: const PlanFormSheet(),
      ),
    );
  }

  Future<void> _openEditSheet(Plan plan) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LatoColors.surfaceDark,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (sheetCtx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: PlanFormSheet(existingPlan: plan),
      ),
    );
  }

  Future<void> _toggleActive(Plan plan, bool next) async {
    try {
      await ref
          .read(planDeactivateControllerProvider.notifier)
          .setActive(plan.id, next);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update plan: $e')),
      );
    }
  }

  void _duplicatePlan(Plan plan) {
    // Duplicating would mean a separate repository operation
    // (`POST /plans/:id/duplicate`); the backend doesn't expose one yet,
    // so the Figma Duplicate button is currently a placeholder.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicate "${plan.name}" — coming soon')),
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: plansAsync.maybeWhen(
          data: (page) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Membership Plans', style: theme.textTheme.headlineSmall),
              const SizedBox(width: LatoSpacing.sm),
              _CountBadge(total: page.total),
            ],
          ),
          orElse: () => Text('Membership Plans', style: theme.textTheme.headlineSmall),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _NewPlanPillButton(onTap: _openCreateSheet),
          ),
        ],
      ),
      body: plansAsync.when(
        data: (page) => _PlansListContent(
          response: page,
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
        loading: () => const LatoLoading(),
        error: (err, _) => LatoErrorState(
          message: err is ApiException ? err.message : 'Could not load plans.',
          onRetry: () => ref.invalidate(planListProvider(query)),
        ),
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
        NumberFormat.decimalPattern().format(total),
        style: const TextStyle(
          color: LatoColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Lime "+ New Plan" pill in the AppBar (44×44 square with + icon, matching
/// the Members screen's add button).
class _NewPlanPillButton extends StatelessWidget {
  const _NewPlanPillButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LatoColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add, color: LatoColors.bgDark, size: 24),
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
    active.sort((a, b) =>
        (b.stats?.activeMembers ?? 0).compareTo(a.stats?.activeMembers ?? 0));
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
    final activeCount = response.summary?.activePlans ?? 0;
    final inactiveCount =
        (response.total - activeCount).clamp(0, response.total);
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
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.xl),
            children: [
              _StatusPill(
                label: 'Active ($activeCount)',
                selected: activeStatus == 'active',
                onTap: () => onSelectStatus(
                  activeStatus == 'active' ? null : 'active',
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              _StatusPill(
                label: 'Paused ($inactiveCount)',
                selected: activeStatus == 'inactive',
                onTap: () => onSelectStatus(
                  activeStatus == 'inactive' ? null : 'inactive',
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              _FilterIconButton(onTap: () {}),
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
          child: plans.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(LatoSpacing.lg),
                    child: LatoEmptyState(
                      icon: Icons.card_membership_outlined,
                      title: isFiltering ? 'No plans match' : 'No plans yet',
                      body: isFiltering
                          ? 'Try a different search or filter.'
                          : 'Create your first plan to start selling memberships.',
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
                    LatoSpacing.xxl,
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
          Text(
            _formatCurrency(revenue),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LatoSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _KpiSubStat(
                  label: 'Sales Volume',
                  value: '${NumberFormat.decimalPattern().format(sales)} sold',
                  valueColor: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: LatoSpacing.lg),
              Expanded(
                child: _KpiSubStat(
                  label: 'Active Members',
                  value:
                      '${NumberFormat.decimalPattern().format(active)} active',
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

String _formatCurrency(double value) {
  final whole = value.truncate();
  final cents =
      ((value - whole).abs() * 100).round().toString().padLeft(2, '0');
  final formattedWhole = NumberFormat.decimalPattern().format(whole);
  return '\$$formattedWhole.$cents';
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
        child: LatoStatusChip(
          label: label,
          tone: selected ? LatoChipTone.primary : LatoChipTone.neutral,
        ),
      ),
    );
  }
}

/// Trailing filter icon button on the status row.
class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: LatoColors.borderDark),
          ),
          child: const Icon(
            Icons.tune,
            size: 18,
            color: LatoColors.textSecondaryDark,
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
        hintText: 'Search plan name, tier, or access code...',
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
                    label: 'Members',
                    value: NumberFormat.decimalPattern()
                        .format(stats?.activeMembers ?? 0),
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatCell(
                    label: 'YTD Sales',
                    value: NumberFormat.decimalPattern()
                        .format(stats?.salesYtd ?? 0),
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatCell(
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
                for (final f in plan.features) _FeatureChip(label: f),
              ],
            ),
          ],
          const SizedBox(height: LatoSpacing.md),
          // Bottom action row
          Row(
            children: [
              _SmallActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: onEdit,
              ),
              const SizedBox(width: LatoSpacing.sm),
              _SmallActionButton(
                icon: Icons.content_copy_outlined,
                label: 'Duplicate',
                onTap: onDuplicate,
              ),
              const Spacer(),
              Text(
                'Active',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(width: LatoSpacing.sm),
              Switch.adaptive(
                value: plan.isActive,
                onChanged: onToggleActive,
                activeThumbColor: LatoColors.primary,
                activeTrackColor:
                    LatoColors.primary.withValues(alpha: 0.35),
                inactiveThumbColor: LatoColors.textSecondaryDark,
                inactiveTrackColor:
                    LatoColors.textSecondaryDark.withValues(alpha: 0.25),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// $142,400 / $342,850.00 style compact currency for the sub-card.
String _formatRevenue(double value) {
  final whole = value.truncate();
  return '\$${NumberFormat.decimalPattern().format(whole)}';
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor,
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
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
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

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: LatoColors.borderDark,
    );
  }
}

/// Small lime-tinted feature chip used inside the plan card.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LatoSpacing.md,
        vertical: LatoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: LatoColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LatoColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: LatoColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Small `Edit` / `Duplicate` text+icon button on the bottom of the plan
/// card. Lighter visual weight than a full TextButton so the card row
/// stays balanced.
class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: LatoSpacing.sm,
          vertical: LatoSpacing.xs,
        ),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: LatoColors.textPrimaryDark,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    );
  }
}

