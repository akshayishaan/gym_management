import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_providers.dart';
import '../core/auth/auth_controller.dart';
import '../core/settings/gym_settings_controller.dart';
import '../data/api_helpers.dart';
import '../data/filters.dart';
import '../data/formatters.dart';
import '../data/plan_providers.dart';
import '../data/query_scope.dart';
import '../layout/shell.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_surface.dart';
import '../widgets/fab.dart';
import '../widgets/hide_scrollbar.dart';
import '../widgets/plan_card.dart';
import '../widgets/plan_form_sheet.dart';

/// Fetches both active and inactive plans (`status: null` omits the param so
/// the backend defaults to "all"), so the client-side segmented filter can
/// toggle without a second request.
const PlanFilters _allPlansFilters = PlanFilters(
  status: null,
  page: 1,
  limit: 100,
  includeStats: true,
);

/// The Plans drill-in screen: revenue hero, active/paused segmented filter,
/// plan cards with admin-only create/edit/duplicate/activate flows. Ported from
/// the web `app/dashboard/plans/page.tsx`.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _showActive = true;

  void _openCreate() => PlanFormSheet.show(context);

  void _openEdit(PlanListResponsePlansInner plan) =>
      PlanFormSheet.show(context, plan: plan);

  void _openDuplicate(PlanListResponsePlansInner plan) =>
      PlanFormSheet.show(context, plan: plan, duplicate: true);

  Future<void> _toggleActive(PlanListResponsePlansInner plan) async {
    if (plan.isActive) {
      await _confirmDeactivate(plan);
    } else {
      await _setActive(plan, true);
    }
  }

  Future<void> _confirmDeactivate(PlanListResponsePlansInner plan) async {
    final int activeMembers = (plan.stats?.activeMembers ?? 0).toInt();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeTokens dt =
            Theme.of(dialogContext).extension<AppThemeTokens>()!.tokens;
        return AlertDialog(
          title: Text('Pause ${plan.name}?'),
          content: Text(
            '$activeMembers active members keep their membership.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep active'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Deactivate',
                style: TextStyle(color: dt.destructive.value),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _setActive(plan, false);
  }

  Future<void> _setActive(PlanListResponsePlansInner plan, bool active) async {
    final dio = ref.read(dioProvider);
    try {
      await putJson<PlanResponse>(
        dio,
        '/plans/${plan.id}',
        data: PlanUpdateInput(isActive: active).toJson(),
        fromJson: PlanResponse.fromJson,
      );
      if (mounted) {
        showAppSnackBar(context, active ? 'Plan activated' : 'Plan deactivated');
        invalidateGymScopeFromWidget(ref);
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Could not update plan', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final String currency = ref.watch(gymSettingsControllerProvider).currency;
    final bool isAdmin =
        ref.watch(authControllerProvider).user?.role == 'admin';

    final AsyncValue<PlanListResponse> plansAsync =
        ref.watch(plansProvider(_allPlansFilters));

    return AppShell(
      mode: ShellMode.stack,
      title: 'Plans',
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
                        _RevenueHero(
                          tokens: t,
                          currency: currency,
                          summary: plansAsync.valueOrNull?.summary,
                          isLoading: plansAsync.isLoading,
                        ),
                        const SizedBox(height: 16),
                        ...plansAsync.when(
                          data: (PlanListResponse data) => _buildBody(
                            t,
                            currency,
                            isAdmin,
                            data,
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
                  child: AppFab(onPressed: _openCreate),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _mostUsedPlanId(List<PlanListResponsePlansInner> plans) {
    String? id;
    num max = 0;
    for (final PlanListResponsePlansInner p in plans) {
      if (!p.isActive) continue;
      final num activeMembers = p.stats?.activeMembers ?? 0;
      if (activeMembers > max) {
        max = activeMembers;
        id = p.id;
      }
    }
    return max == 0 ? null : id;
  }

  List<Widget> _buildBody(
    ThemeTokens t,
    String currency,
    bool isAdmin,
    PlanListResponse data,
  ) {
    final List<PlanListResponsePlansInner> plans = data.plans;
    final int activeCount =
        plans.where((PlanListResponsePlansInner p) => p.isActive).length;
    final int inactiveCount = plans.length - activeCount;
    final String? mostUsedId = _mostUsedPlanId(plans);
    final List<PlanListResponsePlansInner> visible = plans
        .where((PlanListResponsePlansInner p) => p.isActive == _showActive)
        .toList();

    return <Widget>[
      _SegmentedFilter(
        tokens: t,
        showActive: _showActive,
        activeCount: activeCount,
        inactiveCount: inactiveCount,
        onSelect: (bool active) => setState(() => _showActive = active),
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            AppSectionLabel(_showActive ? 'Available now' : 'Paused plans'),
            Text(
              '${visible.length}',
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
      if (plans.isEmpty)
        _emptyState(
          t,
          isAdmin,
          icon: Icons.fitness_center,
          title: 'Build your first plan',
          subtitle: 'Create a membership plan to start selling',
          showCreate: true,
        )
      else if (visible.isEmpty)
        _emptyState(
          t,
          isAdmin,
          icon: _showActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
          title: _showActive ? 'No active plans' : 'Nothing is paused',
          subtitle: _showActive
              ? 'Activate a plan to make it available for purchase'
              : 'Paused plans appear here',
          showCreate: false,
        )
      else
        for (final PlanListResponsePlansInner plan in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlanCard(
              plan: plan,
              currency: currency,
              isMostUsed: plan.id == mostUsedId,
              isAdmin: isAdmin,
              onEdit: () => _openEdit(plan),
              onDuplicate: () => _openDuplicate(plan),
              onToggleActive: () => _toggleActive(plan),
            ),
          ),
    ];
  }

  Widget _emptyState(
    ThemeTokens t,
    bool isAdmin, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showCreate,
  }) {
    return AppSurface(
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
            child: Icon(icon, size: 28, color: t.primary.value),
          ),
          const SizedBox(height: 16),
          Text(
            title,
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
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: t.muted.foreground),
          ),
          if (showCreate && isAdmin) ...<Widget>[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openCreate,
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
              label: const Text('Create plan'),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildLoading(ThemeTokens t) {
    return <Widget>[
      for (int i = 0; i < 4; i++)
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
              'Plans could not load',
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
              onPressed: () => ref.invalidate(plansProvider(_allPlansFilters)),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ];
  }
}

// -- revenue hero -------------------------------------------------------------

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({
    required this.tokens,
    required this.currency,
    required this.summary,
    required this.isLoading,
  });

  final ThemeTokens tokens;
  final String currency;
  final PlanListResponseSummary? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final Color labelColor = withOpacity(t.background, 0.55);

    return AppSurface(
      color: t.foreground,
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Plan revenue · YTD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? '—'
                          : formatCurrency(
                              summary?.revenueAtSaleYtd ?? 0,
                              currency,
                            ),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05 * 32,
                        height: 1,
                        color: t.background,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLoading
                          ? 'From — plan sales'
                          : 'From ${summary?.salesYtd ?? 0} plan sale(s)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: withOpacity(t.background, 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.bar_chart, size: 22, color: t.background),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              _HeroStat(
                value: summary?.activePlans ?? 0,
                label: 'Active plans',
                valueColor: t.success.value,
                labelColor: labelColor,
              ),
              Container(
                width: 1,
                height: 32,
                color: withOpacity(t.background, 0.10),
              ),
              _HeroStat(
                value: summary?.activeMembers ?? 0,
                label: 'Current members',
                valueColor: t.background,
                labelColor: labelColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.labelColor,
  });

  final num value;
  final String label;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value.toInt().toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

// -- segmented filter ---------------------------------------------------------

class _SegmentedFilter extends StatelessWidget {
  const _SegmentedFilter({
    required this.tokens,
    required this.showActive,
    required this.activeCount,
    required this.inactiveCount,
    required this.onSelect,
  });

  final ThemeTokens tokens;
  final bool showActive;
  final int activeCount;
  final int inactiveCount;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.muted.value,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          _SegmentButton(
            tokens: t,
            label: 'Active',
            count: activeCount,
            selected: showActive,
            onTap: () => onSelect(true),
          ),
          _SegmentButton(
            tokens: t,
            label: 'Paused',
            count: inactiveCount,
            selected: !showActive,
            onTap: () => onSelect(false),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.tokens,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final ThemeTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final Color foreground = selected ? t.background : t.muted.foreground;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? t.foreground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              if (count != null) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? t.secondary.value : t.muted.value,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? t.secondary.foreground
                          : t.muted.foreground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
