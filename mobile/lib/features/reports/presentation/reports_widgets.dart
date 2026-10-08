// Private widget helpers for the Reports screen. Splitting these out keeps
// `reports_screen.dart` focused on the screen composition and its local
// state, while the heavier card / chart / list widgets live here.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/money.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../domain/report.dart';

/// `₹1,800` for whole rupees, `₹1,800.50` otherwise. Indian grouping.
String reportMoney(num v) => formatInr(v, decimals: v % 1 == 0 ? 0 : 2);

/// Compact rupee label for chart badges: `₹950`, `₹3.8k`, `₹1.2L`, `₹2.5Cr`.
String reportCompactMoney(num v) {
  String trim(double x) {
    final s = x.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (v >= 10000000) return '₹${trim(v / 10000000)}Cr';
  if (v >= 100000) return '₹${trim(v / 100000)}L';
  if (v >= 1000) return '₹${trim(v / 1000)}k';
  return reportMoney(v);
}

String _count(int n) => NumberFormat.decimalPattern('en_IN').format(n);

String _plural(int n, String one, String many) => n == 1 ? one : many;

const _cardRadius = 12.0;

BoxDecoration _cardDecoration() => BoxDecoration(
  color: LatoColors.surfaceDark,
  borderRadius: BorderRadius.circular(_cardRadius),
  border: Border.all(color: LatoColors.borderDark),
);

const _sectionTitle = TextStyle(
  color: LatoColors.textPrimaryDark,
  fontSize: 15,
  fontWeight: FontWeight.w700,
);

const _caption = TextStyle(
  color: LatoColors.textSecondaryDark,
  fontSize: 11,
  fontWeight: FontWeight.w400,
);

// =================================================================
// Year selector
// =================================================================
class ReportsYearSelector extends StatelessWidget {
  const ReportsYearSelector({
    super.key,
    required this.year,
    required this.onSelect,
    this.currentYear,
  });

  /// Selected year.
  final int year;
  final ValueChanged<int> onSelect;

  /// Most recent year offered (defaults to this year). The selector shows it
  /// and the two years before it; there is no data for the future.
  final int? currentYear;

  @override
  Widget build(BuildContext context) {
    final latest = currentYear ?? DateTime.now().year;
    final years = [latest - 2, latest - 1, latest];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: LatoColors.bgDark,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: LatoColors.borderDark),
          ),
          child: Row(
            children: [
              for (final y in years)
                Expanded(
                  child: _YearButton(
                    label: '$y',
                    selected: y == year,
                    onTap: () => onSelect(y),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: LatoSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 11,
                color: LatoColors.textSecondaryDark,
              ),
              const SizedBox(width: 4),
              Text('1 Jan – 31 Dec $year', style: _caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _YearButton extends StatelessWidget {
  const _YearButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: selected ? LatoColors.surfaceRaisedDark : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? LatoColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? LatoColors.primary
                    : LatoColors.textSecondaryDark,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// Annual revenue hero card
// =================================================================
class ReportsRevenueHeroCard extends StatelessWidget {
  const ReportsRevenueHeroCard({super.key, required this.summary});
  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final revenue = summary.revenue.value;
    final decimals = ((revenue - revenue.truncate()).abs() * 100).round();
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: _cardDecoration(),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LatoColors.primary,
                    LatoColors.primary.withValues(alpha: 0.4),
                    LatoColors.primary.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ANNUAL REVENUE COLLECTED',
                  style: TextStyle(
                    color: LatoColors.textSecondaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(height: LatoSpacing.xs),
                // Same treatment as the Payments total: big rupees, small paise.
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '₹${formatInrWhole(revenue.truncate())}',
                        style: const TextStyle(
                          color: LatoColors.textPrimaryDark,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                      TextSpan(
                        text: '.${decimals.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: LatoColors.textSecondaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LatoSpacing.sm),
                Container(height: 1, color: LatoColors.borderDark),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _HeroSub(
                        label: 'Active Members',
                        value: _count(summary.activeMembers),
                        valueColor: LatoColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(width: LatoSpacing.sm),
                    Expanded(
                      child: _HeroSub(
                        label: 'Outstanding Dues',
                        value: reportMoney(summary.outstandingDues),
                        valueColor: summary.outstandingDues > 0
                            ? LatoColors.error
                            : LatoColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSub extends StatelessWidget {
  const _HeroSub({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LatoColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 2x2 metric grid
// =================================================================
class ReportsMetricGrid extends StatelessWidget {
  const ReportsMetricGrid({super.key, required this.summary});
  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Transactions',
                icon: Icons.trending_up,
                value: _count(summary.transactions.value.round()),
                delta: summary.transactions.changePercentLabel,
              ),
            ),
            const SizedBox(width: LatoSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'New Members',
                icon: Icons.person_add_outlined,
                value: _count(summary.newMembers.value.round()),
                delta: summary.newMembers.changePercentLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: LatoSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Renewals',
                icon: Icons.refresh,
                value: _count(summary.renewals.value.round()),
                delta: summary.renewals.changePercentLabel,
              ),
            ),
            const SizedBox(width: LatoSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'Members with dues',
                icon: Icons.account_balance_wallet_outlined,
                value: _count(summary.dueMembers),
                delta: null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.delta,
  });
  final String label;
  final IconData icon;
  final String value;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.all(LatoSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: LatoColors.textSecondaryDark),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: LatoColors.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (delta != null) ReportsKpiDeltaPill(label: delta!),
            ],
          ),
        ],
      ),
    );
  }
}

/// Change-versus-last-year badge. Renders nothing when there is no earlier
/// year to compare with (the label is the em-dash placeholder).
class ReportsKpiDeltaPill extends StatelessWidget {
  const ReportsKpiDeltaPill({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label == '—') return const SizedBox.shrink();
    final tone = label == '0.0%'
        ? LatoChipTone.neutral
        : label.startsWith('-')
        ? LatoChipTone.error
        : LatoChipTone.success;
    return LatoStatusChip(label: label, tone: tone);
  }
}

// =================================================================
// Monthly trend
// =================================================================
class ReportsTrendCard extends StatelessWidget {
  const ReportsTrendCard({
    super.key,
    required this.series,
    required this.bestMonth,
    required this.trendMode,
    required this.onToggle,
  });
  final List<ReportSeriesPoint> series;
  final ReportBestMonth? bestMonth;
  final String trendMode;
  final ValueChanged<String> onToggle;

  double _valueFor(ReportSeriesPoint p) =>
      trendMode == 'revenue' ? p.revenue.toDouble() : p.newMembers.toDouble();

  /// Month with the highest value for the selected mode, or null when every
  /// month is zero.
  ReportSeriesPoint? get _peak {
    ReportSeriesPoint? best;
    for (final p in series) {
      if (_valueFor(p) <= 0) continue;
      if (best == null || _valueFor(p) > _valueFor(best)) best = p;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final peak = _peak;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Monthly trend', style: _sectionTitle),
              ),
              _TrendModeSwitch(mode: trendMode, onToggle: onToggle),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          if (peak != null) ...[
            _PeakCallout(
              monthName: DateFormat.MMMM().format(DateTime(0, peak.month)),
              revenueMode: trendMode == 'revenue',
              value: _valueFor(peak),
            ),
            const SizedBox(height: LatoSpacing.sm),
          ],
          SizedBox(
            height: 180,
            child: _BarChart(
              series: series,
              mode: trendMode,
              peakMonth: peak?.month,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendModeSwitch extends StatelessWidget {
  const _TrendModeSwitch({required this.mode, required this.onToggle});
  final String mode;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LatoColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchSegment(
            label: 'Revenue',
            selected: mode == 'revenue',
            onTap: () => onToggle('revenue'),
          ),
          _SwitchSegment(
            label: 'Members',
            selected: mode == 'members',
            onTap: () => onToggle('members'),
          ),
        ],
      ),
    );
  }
}

class _SwitchSegment extends StatelessWidget {
  const _SwitchSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? LatoColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? LatoColors.bgDark
                    : LatoColors.textSecondaryDark,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeakCallout extends StatelessWidget {
  const _PeakCallout({
    required this.monthName,
    required this.revenueMode,
    required this.value,
  });
  final String monthName;
  final bool revenueMode;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 11),
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LatoColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: LatoColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    revenueMode
                        ? 'Peak Volume: $monthName'
                        : 'Most new members: $monthName',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LatoColors.textPrimaryDark,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            revenueMode ? reportMoney(value) : _count(value.round()),
            style: const TextStyle(
              color: LatoColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.series,
    required this.mode,
    required this.peakMonth,
  });
  final List<ReportSeriesPoint> series;
  final String mode;
  final int? peakMonth;

  double _valueFor(ReportSeriesPoint p) =>
      mode == 'revenue' ? p.revenue.toDouble() : p.newMembers.toDouble();

  String _badge(double value) =>
      mode == 'revenue' ? reportCompactMoney(value) : _count(value.round());

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final maxVal = series
        .map(_valueFor)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return LayoutBuilder(
      builder: (context, constraints) {
        const barGap = 4.0;
        final barWidth =
            ((constraints.maxWidth - (barGap * (series.length - 1))) /
                    series.length)
                .clamp(4.0, 40.0);
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < series.length; i++) ...[
                if (i > 0) const SizedBox(width: barGap),
                _BarColumn(
                  width: barWidth,
                  seriesPoint: series[i],
                  value: _valueFor(series[i]),
                  maxValue: maxVal,
                  isPeak: peakMonth != null && series[i].month == peakMonth,
                  badgeLabel: _badge(_valueFor(series[i])),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.width,
    required this.seriesPoint,
    required this.value,
    required this.maxValue,
    required this.isPeak,
    required this.badgeLabel,
  });
  final double width;
  final ReportSeriesPoint seriesPoint;
  final double value;
  final double maxValue;
  final bool isPeak;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final trackHeight = c.maxHeight - 18;
              final ratio = maxValue == 0
                  ? 0.04
                  : (value / maxValue).clamp(0.04, 1.0);
              final barHeight = trackHeight * ratio;
              return Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: width,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: isPeak
                          ? LatoColors.primary
                          : LatoColors.borderStrongDark,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  if (isPeak)
                    Positioned(
                      bottom: barHeight + 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: LatoColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          badgeLabel,
                          softWrap: false,
                          style: const TextStyle(
                            color: LatoColors.bgDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          seriesPoint.monthShort,
          style: TextStyle(
            color: isPeak ? LatoColors.primary : LatoColors.textSecondaryDark,
            fontSize: 10,
            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// =================================================================
// Member Lifecycle & Health
// =================================================================
class ReportsLifecycleList extends StatelessWidget {
  const ReportsLifecycleList({
    super.key,
    required this.insights,
    required this.summary,
  });
  final ReportInsights insights;
  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final expiring = insights.expiringSoon;
    final owing = insights.dueMembers;
    final expired = insights.expiredMembers;
    final denom = (summary.activeMembers + expired).clamp(1, 1 << 30);
    final churnRate = (expired / denom) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Member Lifecycle & Health', style: _sectionTitle),
        const SizedBox(height: LatoSpacing.sm),
        _LifecycleRow(
          iconTile: const _IconTile(icon: Icons.hourglass_bottom),
          title: 'Expiring in 30 Days',
          subtitle: expiring == 0
              ? 'No memberships expire in the next 30 days'
              : '$expiring ${_plural(expiring, 'membership expires', 'memberships expire')} in the next 30 days',
        ),
        _LifecycleRow(
          iconTile: _IconTile(
            icon: Icons.error_outline,
            iconColor: owing > 0 ? LatoColors.error : null,
            background: owing > 0 ? LatoColors.tint(LatoColors.error) : null,
            border: owing > 0 ? LatoColors.error.withValues(alpha: 0.3) : null,
          ),
          title: 'Outstanding Dues',
          subtitle: owing == 0
              ? 'No outstanding dues'
              : '$owing ${_plural(owing, 'member owes', 'members owe')} ${reportMoney(insights.outstandingDues)}',
          subtitleColor: owing > 0 ? LatoColors.error : null,
          action: owing > 0
              ? const LatoStatusChip(
                  label: 'Action needed',
                  tone: LatoChipTone.error,
                )
              : null,
        ),
        _LifecycleRow(
          iconTile: const _IconTile(icon: Icons.person_off_outlined),
          title: 'Expired / Churned',
          subtitle: expired == 0
              ? 'No expired members'
              : '$expired ${_plural(expired, 'member', 'members')} expired',
          action: LatoStatusChip(
            label: '${churnRate.toStringAsFixed(1)}% churn',
          ),
        ),
      ],
    );
  }
}

class _LifecycleRow extends StatelessWidget {
  const _LifecycleRow({
    required this.iconTile,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.action,
  });
  final Widget iconTile;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LatoSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(LatoSpacing.md),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            iconTile,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LatoColors.textPrimaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _caption.copyWith(
                      color: subtitleColor ?? LatoColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: LatoSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    this.background,
    this.border,
    this.iconColor,
  });
  final IconData icon;
  final Color? background;
  final Color? border;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background ?? LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border ?? LatoColors.borderDark),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 16,
        color: iconColor ?? LatoColors.textSecondaryDark,
      ),
    );
  }
}

// =================================================================
// Membership Plan Distribution
// =================================================================
class ReportsPlanDistribution extends StatelessWidget {
  const ReportsPlanDistribution({super.key, required this.plans});
  final List<ReportPlanPerformance> plans;

  @override
  Widget build(BuildContext context) {
    final sorted = [...plans]..sort((a, b) => b.revenue.compareTo(a.revenue));
    final totalRevenue = sorted.fold<double>(0, (sum, p) => sum + p.revenue);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Membership Plan Distribution', style: _sectionTitle),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LatoSpacing.sm),
              child: Text(
                'No plan performance data for this year.',
                style: _caption.copyWith(fontSize: 12),
              ),
            )
          else
            for (int i = 0; i < sorted.length; i++) ...[
              _PlanRow(
                plan: sorted[i],
                rank: i,
                totalRevenue: totalRevenue,
                isEmpty: totalRevenue == 0,
              ),
              if (i < sorted.length - 1) const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.rank,
    required this.totalRevenue,
    required this.isEmpty,
  });
  final ReportPlanPerformance plan;
  final int rank;
  final double totalRevenue;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final pct = isEmpty
        ? 0.0
        : ((plan.revenue / totalRevenue) * 100).clamp(0, 100).toDouble();
    final isUnlinked =
        plan.planId == null ||
        plan.planId!.isEmpty ||
        plan.key.startsWith('legacy:') ||
        plan.key == '__unassigned__';
    final isTop = rank == 0 && !isUnlinked;
    final members = plan.activeMembers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isUnlinked ? 'Unlinked plan' : plan.name,
                style: const TextStyle(
                  color: LatoColors.textPrimaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              reportMoney(plan.revenue),
              style: TextStyle(
                color: isTop ? LatoColors.primary : LatoColors.textPrimaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isEmpty ? '0.0%' : '(${pct.toStringAsFixed(1)}%)',
              style: _caption,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (!isEmpty)
          SizedBox(
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (pct / 100).clamp(0.0, 1.0),
                  child: Container(color: _colorForRank(rank, isUnlinked)),
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 8),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${_count(members)} ${_plural(members, 'member', 'members')}',
              style: _caption,
            ),
            const Spacer(),
            Text(
              '${reportMoney(members > 0 ? plan.revenue / members : 0)} avg per member',
              style: _caption,
            ),
          ],
        ),
      ],
    );
  }

  Color _colorForRank(int rank, bool isUnlinked) {
    if (isUnlinked) return LatoColors.borderStrongDark;
    switch (rank) {
      case 0:
        return LatoColors.primary;
      case 1:
        return LatoColors.textSecondaryDark;
      default:
        return LatoColors.borderStrongDark;
    }
  }
}

// =================================================================
// Payment Channels
// =================================================================
class ReportsPaymentChannels extends StatelessWidget {
  const ReportsPaymentChannels({super.key, required this.methods});
  final List<ReportPaymentMethod> methods;

  static const _methodLabels = {
    'cash': 'Cash',
    'card': 'Card',
    'upi': 'UPI',
    'bank_transfer': 'Bank Transfer',
    'other': 'Other',
  };

  String _labelFor(String method) => _methodLabels[method] ?? 'Other';

  /// Cash carries the accent; the rest are neutral steps so the bar reads
  /// without introducing new hues.
  Color _colorFor(String method) {
    switch (method) {
      case 'cash':
        return LatoColors.primary;
      case 'upi':
        return LatoColors.textSecondaryDark;
      case 'card':
        return LatoColors.textPrimaryDark.withValues(alpha: 0.6);
      case 'bank_transfer':
        return LatoColors.borderStrongDark;
      default:
        return LatoColors.textSecondaryDark.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gross = methods.fold<double>(0, (s, m) => s + m.amount);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Channels', style: _sectionTitle),
              Text('Gross: ${reportCompactMoney(gross)}', style: _caption),
            ],
          ),
          const SizedBox(height: 12),
          if (gross > 0)
            _SegmentedBar(methods: methods, colorFor: _colorFor)
          else
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: LatoColors.surfaceRaisedDark,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          const SizedBox(height: 12),
          if (methods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No payment data for this year.',
                style: _caption.copyWith(fontSize: 12),
              ),
            )
          else
            for (final m in methods)
              _MethodRow(
                method: m,
                color: _colorFor(m.method),
                label: _labelFor(m.method),
              ),
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({required this.methods, required this.colorFor});
  final List<ReportPaymentMethod> methods;
  final Color Function(String) colorFor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          for (int i = 0; i < methods.length; i++) ...[
            Expanded(
              flex: methods[i].amount.round().clamp(0, 1 << 30),
              child: Container(color: colorFor(methods[i].method)),
            ),
            if (i < methods.length - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.method,
    required this.color,
    required this.label,
  });
  final ReportPaymentMethod method;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(LatoSpacing.md),
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LatoColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: LatoColors.textPrimaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_count(method.count)} ${_plural(method.count, 'transaction', 'transactions')}',
                  style: _caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                reportMoney(method.amount),
                style: const TextStyle(
                  color: LatoColors.textPrimaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${method.percentage.toStringAsFixed(1)}%',
                style: _caption.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
