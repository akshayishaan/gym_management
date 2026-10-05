// Private widget helpers for the Reports screen. Splitting these out keeps
// `reports_screen.dart` focused on the screen composition and its local
// state, while the heavier card / chart / list widgets live here.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../design/colors.dart';
import '../domain/report.dart';

// --- Brand tokens used inside the Reports feature ---
const Color kReportSurface = Color(0xFF181C22);
const Color kReportSurfaceAlt = Color(0xFF1C2026);
const Color kReportSurfaceSelected = Color(0xFF262A31);
const Color kReportBorder = Color(0xFF31353C);
const Color kReportBorderStrong = Color(0xB331353C);
const Color kReportSage = Color(0xFFC4C9AC);
const Color kReportSageDim = Color(0xFF8E9379);
const Color kReportLime = Color(0xFFC3F400);
const Color kReportLimeDark = Color(0xFF556D00);
const Color kReportLimeSelectedBorder = Color(0x4DC3F400);
const Color kReportLimeSoftBg = Color(0x1AC3F400);
const Color kReportPeach = Color(0xFFFFB59C);
const Color kReportPeachSoftBg = Color(0x1AFFB59C);
const Color kReportPeachBorder = Color(0x4DFFB59C);
const Color kReportPeachAccentSoft = Color(0x26FF5708);
const Color kReportCyan = Color(0xFF7DF4FF);
const Color kReportCyan2 = Color(0xFF00DBE9);
const Color kReportGray = Color(0xFF31353C);
const Color kReportBgd = Color(0xFF0A0E14);

final NumberFormat kReportCurrency = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 2,
);

String reportKFormat(double v) {
  if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
  return kReportCurrency.format(v);
}

// =================================================================
// Year selector
// =================================================================
class ReportsYearSelector extends StatelessWidget {
  const ReportsYearSelector({
    super.key,
    required this.year,
    required this.onSelect,
  });
  final int year;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: kReportBgd,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kReportBorder),
          ),
          child: Row(
            children: [
              for (final y in [year - 1, year, year + 1])
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
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 11,
                color: kReportSageDim,
              ),
              const SizedBox(width: 4),
              Text(
                'Jan 1 – Dec 31, $year',
                style: const TextStyle(
                  color: kReportSageDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kReportSurfaceSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: kReportLimeSelectedBorder)
                : Border.all(color: Colors.transparent),
            boxShadow: selected
                ? [
                    BoxShadow(
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? kReportLime : kReportSage,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
  const ReportsRevenueHeroCard({
    super.key,
    required this.summary,
  });
  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: kReportSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kReportBorder),
        boxShadow: const [
          BoxShadow(
            blurRadius: 50,
            offset: Offset(0, 25),
            spreadRadius: -12,
            color: Colors.black26,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFC5F23F),
                    Color(0xFFABD600),
                    Color(0x00ABD600),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ANNUAL REVENUE COLLECTED',
                  style: TextStyle(
                    color: kReportSageDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kReportCurrency.format(summary.revenue.value),
                  style: const TextStyle(
                    color: LatoColors.textPrimaryDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Container(height: 1, color: kReportBorder),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _HeroSub(
                        label: 'Active Members',
                        value: NumberFormat.decimalPattern()
                            .format(summary.activeMembers),
                        valueColor: const Color(0xFFDFE2EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroSub(
                        label: 'Outstanding Dues',
                        value: kReportCurrency.format(summary.outstandingDues),
                        valueColor: kReportPeach,
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
        color: kReportSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kReportBorderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kReportSage,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
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
                value: NumberFormat.decimalPattern()
                    .format(summary.transactions.value),
                delta: summary.transactions.changePercentLabel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'New Members',
                icon: Icons.person_add_outlined,
                value: NumberFormat.decimalPattern()
                    .format(summary.newMembers.value),
                delta: summary.newMembers.changePercentLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Renewals',
                icon: Icons.refresh,
                value: NumberFormat.decimalPattern()
                    .format(summary.renewals.value),
                delta: summary.renewals.changePercentLabel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Members w/ Dues',
                icon: Icons.account_balance_wallet_outlined,
                value: NumberFormat.decimalPattern().format(summary.dueMembers),
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
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: kReportSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kReportBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kReportSageDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 14, color: kReportSageDim),
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

class ReportsKpiDeltaPill extends StatelessWidget {
  const ReportsKpiDeltaPill({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isZero = label == '0.0%' || label == '—';
    final isNegative = !isZero && label.startsWith('-');
    final bg = isZero
        ? kReportLimeSoftBg
        : isNegative
            ? kReportPeachSoftBg
            : kReportLimeSoftBg;
    final fg = isZero
        ? kReportLime
        : isNegative
            ? kReportPeach
            : kReportLime;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =================================================================
// 12-Month Performance Trend
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: kReportSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kReportBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '12-Month Performance\nTrend',
                      style: TextStyle(
                        color: LatoColors.textPrimaryDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.33,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Annual trajectory overview',
                      style: TextStyle(
                        color: kReportSage,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TrendModeSwitch(mode: trendMode, onToggle: onToggle),
            ],
          ),
          const SizedBox(height: 8),
          if (bestMonth != null) _PeakCallout(bestMonth: bestMonth!),
          if (bestMonth != null) const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: _BarChart(
              series: series,
              mode: trendMode,
              bestMonth: bestMonth,
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
        color: kReportSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kReportBorder),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? kReportLime : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? kReportLimeDark : kReportSage,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _PeakCallout extends StatelessWidget {
  const _PeakCallout({required this.bestMonth});
  final ReportBestMonth bestMonth;

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat.MMMM().format(DateTime(0, bestMonth.month));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 11),
      decoration: BoxDecoration(
        color: kReportSurfaceSelected,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kReportBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: kReportLime,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Peak Volume: $monthName',
                style: const TextStyle(
                  color: LatoColors.textPrimaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Text(
            kReportCurrency.format(bestMonth.revenue),
            style: const TextStyle(
              color: kReportLime,
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
    required this.bestMonth,
  });
  final List<ReportSeriesPoint> series;
  final String mode;
  final ReportBestMonth? bestMonth;

  double _valueFor(ReportSeriesPoint p) {
    return mode == 'revenue' ? p.revenue.toDouble() : p.newMembers.toDouble();
  }

  String _formatLabel(double value) {
    if (mode == 'revenue') {
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final maxVal = series.map(_valueFor).fold<double>(0, (a, b) => a > b ? a : b);
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth;
        final barGap = 4.0;
        final barWidth =
            ((chartWidth - (barGap * (series.length - 1))) / series.length)
                .clamp(4.0, 40.0);
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < series.length; i++) ...[
                if (i > 0) SizedBox(width: barGap),
                _BarColumn(
                  width: barWidth,
                  seriesPoint: series[i],
                  value: _valueFor(series[i]),
                  maxValue: maxVal,
                  isPeak: bestMonth != null && series[i].month == bestMonth!.month,
                  badgeLabel: _formatLabel(_valueFor(series[i])),
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
                      color: isPeak ? kReportLime : kReportBorder,
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
                          color: kReportLime,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: kReportLimeDark,
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
            color: isPeak ? kReportLime : kReportSageDim,
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
    required this.onRemind,
  });
  final ReportInsights insights;
  final ReportSummary summary;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final denom =
        (summary.activeMembers + insights.expiredMembers).clamp(1, 1 << 30);
    final churnRate = (insights.expiredMembers / denom) * 100;
    final churnLabel = '${churnRate.toStringAsFixed(1)}% Rate';
    final duesFormatted = kReportCurrency.format(insights.outstandingDues);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Member Lifecycle & Health',
          style: TextStyle(
            color: LatoColors.textPrimaryDark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _LifecycleRow(
          iconTile: const _IconTile(
            background: kReportSurfaceSelected,
            border: kReportBorder,
            icon: Icons.hourglass_bottom,
          ),
          title: 'Expiring in 30 Days',
          subtitle:
              '${insights.expiringSoon} memberships expiring this cycle',
          action: _Pill(
            label: 'Remind All',
            bg: kReportLime,
            fg: kReportLimeDark,
            onTap: onRemind,
          ),
        ),
        _LifecycleRow(
          iconTile: const _IconTile(
            background: kReportPeachAccentSoft,
            border: kReportPeachBorder,
            icon: Icons.error_outline,
            iconColor: kReportPeach,
          ),
          title: 'Outstanding Dues',
          subtitle:
              '${insights.dueMembers} accounts delinquent ($duesFormatted)',
          subtitleColor: kReportPeach,
          action: const _Pill(
            label: 'Action Req.',
            bg: kReportPeachAccentSoft,
            fg: kReportPeach,
            border: kReportPeachBorder,
            borderWidth: 0.5,
            radius: 4,
            padH: 9,
            padV: 5,
          ),
        ),
        _LifecycleRow(
          iconTile: const _IconTile(
            background: kReportSurfaceSelected,
            border: kReportBorder,
            icon: Icons.person_off_outlined,
          ),
          title: 'Expired / Churned',
          subtitle:
              '${insights.expiredMembers} accounts • Low churn benchmark',
          action: _Pill(
            label: churnLabel,
            bg: kReportLimeSoftBg,
            fg: kReportLime,
            border: const Color(0x33C3F400),
            radius: 4,
            padH: 9,
            padV: 3,
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
    required this.action,
  });
  final Widget iconTile;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: kReportSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kReportBorder),
        ),
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
                    style: TextStyle(
                      color: subtitleColor ?? kReportSage,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            action,
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.background,
    required this.border,
    required this.icon,
    this.iconColor = kReportSage,
  });
  final Color background;
  final Color border;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: iconColor),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.border,
    this.borderWidth = 1,
    this.radius = 8,
    this.padH = 10,
    this.padV = 6,
    this.onTap,
  });
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;
  final double borderWidth;
  final double radius;
  final double padH;
  final double padV;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border != null
            ? Border.all(color: border!, width: borderWidth)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: child,
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
    final totalRevenue =
        sorted.fold<double>(0, (sum, p) => sum + p.revenue);
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: BoxDecoration(
        color: kReportSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kReportBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Membership Plan Distribution',
            style: TextStyle(
              color: LatoColors.textPrimaryDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No plan performance data for this year.',
                style: TextStyle(
                  color: kReportSage,
                  fontSize: 12,
                ),
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
    final pctLabel = '${pct.toStringAsFixed(1)}%';
    final avgPerYear = plan.activeMembers > 0
        ? kReportCurrency.format(plan.revenue / plan.activeMembers)
        : kReportCurrency.format(0);
    final isUnlinked = plan.planId == null ||
        plan.planId!.isEmpty ||
        plan.key.startsWith('legacy:') ||
        plan.key == '__unassigned__';
    final color = _colorForRank(rank, isUnlinked);
    final isTop = rank == 0 && !isUnlinked;
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
              kReportCurrency.format(plan.revenue),
              style: TextStyle(
                color: isTop ? kReportLime : LatoColors.textPrimaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isEmpty ? '0.0%' : '($pctLabel)',
              style: const TextStyle(
                color: kReportSage,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
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
                  child: Container(color: color),
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
              '${NumberFormat.decimalPattern().format(plan.activeMembers)} Members',
              style: const TextStyle(
                color: kReportSage,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              '$avgPerYear Avg/Yr',
              style: const TextStyle(
                color: kReportSage,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _colorForRank(int rank, bool isUnlinked) {
    if (isUnlinked) return kReportGray;
    switch (rank) {
      case 0:
        return kReportLime;
      case 1:
        return kReportCyan;
      case 2:
        return kReportSageDim;
      default:
        return kReportGray;
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

  static const _methodColors = {
    'cash': kReportLime,
    'card': kReportCyan2,
    'upi': kReportSageDim,
    'bank_transfer': kReportGray,
    'other': Color(0xFF6B6B6B),
  };

  String _labelFor(String method) => _methodLabels[method] ?? 'Other';

  Color _colorFor(String method) =>
      _methodColors[method] ?? const Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    final gross = methods.fold<double>(0, (s, m) => s + m.amount);
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
      decoration: BoxDecoration(
        color: kReportSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kReportBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Channels',
                style: TextStyle(
                  color: LatoColors.textPrimaryDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Gross: ${reportKFormat(gross)}',
                style: const TextStyle(
                  color: kReportSage,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (gross > 0)
            _SegmentedBar(methods: methods, colorFor: _colorFor)
          else
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: kReportSurfaceAlt,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          const SizedBox(height: 12),
          if (methods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No payment data for this year.',
                style: TextStyle(
                  color: kReportSage,
                  fontSize: 12,
                ),
              ),
            )
          else
            for (int i = 0; i < methods.length; i++)
              _MethodRow(
                method: methods[i],
                color: _colorFor(methods[i].method),
                label: _labelFor(methods[i].method),
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
        color: kReportSurfaceAlt,
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
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: kReportSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x8031353C)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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
                  '${NumberFormat.decimalPattern().format(method.count)} Transactions',
                  style: const TextStyle(
                    color: kReportSage,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                kReportCurrency.format(method.amount),
                style: const TextStyle(
                  color: LatoColors.textPrimaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${method.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: kReportSage,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}