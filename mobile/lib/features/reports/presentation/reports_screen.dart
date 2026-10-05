// Phase 8 Track C — Reports (Financial & Member). Mirrors the Figma
// `2:2861` "Gym Financial & Member Reports" node. All sections are live
// via `reportsProvider`; share / remind-all are placeholder SnackBars.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_loading.dart';
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

  void _showSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Financial & Member Reports',
          style: theme.textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showSoon('Share reports — coming soon'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LatoLoading(),
        error: (err, _) => LatoErrorState(
          message:
              err is ApiException ? err.message : 'Could not load reports.',
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
                ReportsYearSelector(
                  year: _selectedYear,
                  onSelect: _setYear,
                ),
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
                  onRemind: () => _showSoon('Remind all — coming soon'),
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