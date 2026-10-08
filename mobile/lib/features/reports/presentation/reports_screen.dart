// Phase 8 Track C — Reports (Financial & Member). Mirrors the Figma
// `2:2861` "Gym Financial & Member Reports" node. All sections are live
// via `reportsProvider`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/back_navigation.dart';
import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_skeleton.dart';
import '../../../design/spacing.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';
import 'reports_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late int _selectedYear;
  String _trendMode = 'revenue'; // 'revenue' | 'members'

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  void _setYear(int year) {
    if (year == _selectedYear) return;
    setState(() => _selectedYear = year);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reportsProvider(_selectedYear));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: LatoColors.bgDark,
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, kMoreMenuRoute),
        ),
        title: Text('Reports', style: theme.textTheme.headlineSmall),
      ),
      body: async.when(
        loading: () => const _ReportsSkeleton(),
        error: (err, _) => LatoErrorState(
          message: err is ApiException
              ? err.message
              : 'Could not load reports.',
          onRetry: () => ref.invalidate(reportsProvider(_selectedYear)),
        ),
        data: (report) {
          if (_isEmptyReport(report)) {
            return _EmptyReports(
              onSwitchYear: () => _setYear(_selectedYear - 1),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              LatoSpacing.xl,
              LatoSpacing.sm,
              LatoSpacing.xl,
              LatoSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportsYearSelector(year: _selectedYear, onSelect: _setYear),
                const SizedBox(height: 24),
                ReportsRevenueHeroCard(summary: report.summary),
                const SizedBox(height: 24),
                ReportsMetricGrid(summary: report.summary),
                const SizedBox(height: 24),
                ReportsTrendCard(
                  series: report.series,
                  bestMonth: report.insights.bestMonth,
                  trendMode: _trendMode,
                  onToggle: (m) => setState(() => _trendMode = m),
                ),
                const SizedBox(height: 24),
                ReportsLifecycleList(
                  insights: report.insights,
                  summary: report.summary,
                ),
                const SizedBox(height: 24),
                ReportsPlanDistribution(plans: report.planPerformance),
                const SizedBox(height: 24),
                ReportsPaymentChannels(methods: report.paymentMethods),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isEmptyReport(ReportsResponse r) {
    final s = r.series;
    if (s.isEmpty) return true;
    if (r.summary.activeMembers != 0) return false;
    final allZero = s.every((p) => p.revenue == 0 && p.newMembers == 0);
    return r.summary.outstandingDues == 0 && allZero;
  }
}

/// First-load placeholder: year selector, hero revenue card, metric grid,
/// trend chart and two list cards, with the screen's padding and 24px gaps.
class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  static const _gap = SizedBox(height: 24);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SingleChildScrollView(
        key: const Key('reports-skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.xl,
          LatoSpacing.sm,
          LatoSpacing.xl,
          LatoSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                LatoSkeletonBlock(width: 72, height: 36, radius: LatoRadius.pill),
                SizedBox(width: LatoSpacing.sm),
                LatoSkeletonBlock(width: 72, height: 36, radius: LatoRadius.pill),
                SizedBox(width: LatoSpacing.sm),
                LatoSkeletonBlock(width: 72, height: 36, radius: LatoRadius.pill),
              ],
            ),
            _gap,
            const LatoSkeletonBlock(height: 132, radius: LatoRadius.lg),
            _gap,
            const Row(
              children: [
                Expanded(child: LatoSkeletonBlock(height: 92, radius: LatoRadius.lg)),
                SizedBox(width: LatoSpacing.md),
                Expanded(child: LatoSkeletonBlock(height: 92, radius: LatoRadius.lg)),
              ],
            ),
            const SizedBox(height: LatoSpacing.md),
            const Row(
              children: [
                Expanded(child: LatoSkeletonBlock(height: 92, radius: LatoRadius.lg)),
                SizedBox(width: LatoSpacing.md),
                Expanded(child: LatoSkeletonBlock(height: 92, radius: LatoRadius.lg)),
              ],
            ),
            _gap,
            const LatoSkeletonBlock(height: 240, radius: LatoRadius.lg),
            _gap,
            const LatoSkeletonBlock(height: 160, radius: LatoRadius.lg),
            _gap,
            const LatoSkeletonBlock(height: 160, radius: LatoRadius.lg),
          ],
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports({required this.onSwitchYear});
  final VoidCallback onSwitchYear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LatoSpacing.lg),
        child: LatoEmptyState(
          icon: Icons.bar_chart,
          title: 'No data for this year',
          body: 'Reports will populate as activity accrues.',
          actionLabel: 'Switch Year',
          onAction: onSwitchYear,
        ),
      ),
    );
  }
}
