import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/navigation.dart';
import '../core/settings/gym_settings_controller.dart';
import '../data/formatters.dart';
import '../data/report_providers.dart';
import '../layout/shell.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';
import '../widgets/hide_scrollbar.dart';
import '../widgets/report_trend_chart.dart';

const Map<String, String> _methodLabels = <String, String>{
  'cash': 'Cash',
  'card': 'Card',
  'upi': 'UPI',
  'bank_transfer': 'Bank transfer',
  'other': 'Other',
};

/// Converts a method's percentage into a non-zero [Row] flex factor so the
/// stacked bar never collapses an entry (e.g. a 0% rounding).
int _barFlex(num percentage) {
  final int rounded = percentage.round();
  return rounded < 1 ? 1 : rounded;
}

/// Formats [v] as an unsigned percentage string with a trailing `.0` dropped
/// (e.g. `12.5` → `"12.5"`, `12.0` → `"12"`, `0` → `"0"`). The sign is carried
/// separately by the arrow icons, so it is discarded here.
String _formatPercent(num v) {
  String s = v.abs().toString();
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  return s;
}

/// The Reports drill-in screen: collected-in-year hero, a glanceable metric
/// grid, a monthly trend chart, member-health deep links, plan performance and
/// payment-method breakdown. Read-only; no admin gating. Ported from the web
/// `app/dashboard/reports/page.tsx`.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    // Device-local *navigation/form* default (like `currentMonthKey()` in
    // `formatters.dart`). All *rendered* business values come from the server
    // response — consistent with ADR-0005 (no client-side business date math).
    _year = DateTime.now().year;
  }

  void _prevYear() => setState(() => _year -= 1);

  void _nextYear() {
    if (_year >= DateTime.now().year) return;
    setState(() => _year += 1);
  }

  void _goToMembers(String status) {
    ref.read(membersStatusProvider.notifier).state = status;
    ref.read(selectedTabIndexProvider.notifier).state = 1;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final String currency = ref.watch(gymSettingsControllerProvider).currency;
    final bool atCurrentYear = _year >= DateTime.now().year;

    final AsyncValue<ReportsResponse> reportsAsync =
        ref.watch(reportsProvider(_year));

    return AppShell(
      mode: ShellMode.stack,
      title: 'Reports',
      selectedIndex: 3,
      onSelectTab: (_) {},
      onBack: () => Navigator.of(context).maybePop(),
      actions: <Widget>[
        IconButton(
          onPressed: _prevYear,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '$_year',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: t.foreground,
          ),
        ),
        IconButton(
          onPressed: atCurrentYear ? null : _nextYear,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HideScrollBar(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: reportsAsync.when(
                  data: (ReportsResponse data) =>
                      _buildContent(t, currency, data),
                  loading: () => _buildLoading(t),
                  error: (Object e, StackTrace st) => _buildError(t),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    ThemeTokens t,
    String currency,
    ReportsResponse data,
  ) {
    final ReportsResponseSummary summary = data.summary;
    final ReportsResponseInsights insights = data.insights;

    return <Widget>[
      _CollectedHero(
        tokens: t,
        currency: currency,
        year: _year,
        summary: summary,
      ),
      const SizedBox(height: 24),
      const AppSectionLabel('Year at a glance'),
      const SizedBox(height: 12),
      _glanceGrid(t, currency, summary),
      const SizedBox(height: 24),
      const AppSectionLabel('Year in motion'),
      const SizedBox(height: 12),
      AppSurface(
        borderRadius: BorderRadius.circular(t.radius * 1.55),
        padding: const EdgeInsets.all(16),
        child: ReportTrendChart(series: data.series, currency: currency),
      ),
      const SizedBox(height: 24),
      const AppSectionLabel('Live member health'),
      const SizedBox(height: 12),
      _memberHealth(t, currency, insights),
      const SizedBox(height: 24),
      const AppSectionLabel('Plan performance'),
      const SizedBox(height: 12),
      _planPerformance(t, currency, data.planPerformance),
      const SizedBox(height: 24),
      const AppSectionLabel('How members paid'),
      const SizedBox(height: 12),
      _paymentMethods(t, currency, data.paymentMethods),
    ];
  }

  Widget _glanceGrid(
    ThemeTokens t,
    String currency,
    ReportsResponseSummary summary,
  ) {
    final List<Widget> cards = <Widget>[
      _MetricCard(
        icon: Icons.credit_card,
        color: t.primary.value,
        value: summary.transactions.value.toInt().toString(),
        label: 'Transactions',
        changePercent: summary.transactions.changePercent,
      ),
      _MetricCard(
        icon: Icons.people_outline,
        color: t.accent.value,
        value: summary.newMembers.value.toInt().toString(),
        label: 'New members',
        changePercent: summary.newMembers.changePercent,
      ),
      _MetricCard(
        icon: Icons.repeat,
        color: t.success.value,
        value: summary.renewals.value.toInt().toString(),
        label: 'Renewals',
        changePercent: summary.renewals.changePercent,
      ),
      _MetricCard(
        icon: Icons.wallet,
        color: t.warning.value,
        value: summary.dueMembers.toInt().toString(),
        label: 'Members with dues',
        detail: formatCurrency(summary.outstandingDues, currency),
      ),
    ];

    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _memberHealth(
    ThemeTokens t,
    String currency,
    ReportsResponseInsights insights,
  ) {
    final ReportsResponseInsightsBestMonth? bestMonth = insights.bestMonth;

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.55),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: <Widget>[
          _HealthRow(
            icon: Icons.warning_amber_rounded,
            color: t.warning.value,
            title: 'Expiring in 30 days',
            value: insights.expiringSoon.toInt().toString(),
            onTap: () => _goToMembers('expiring30'),
          ),
          _HealthRow(
            icon: Icons.error_outline,
            color: t.destructive.value,
            title: 'Outstanding dues',
            value: formatCurrency(insights.outstandingDues, currency),
            subtitle: '${insights.dueMembers.toInt()} members',
            onTap: () => _goToMembers('due'),
          ),
          _HealthRow(
            icon: Icons.timer_off_outlined,
            color: t.muted.foreground,
            title: 'Expired memberships',
            value: insights.expiredMembers.toInt().toString(),
            onTap: () => _goToMembers('expired'),
          ),
          _HealthRow(
            icon: Icons.emoji_events,
            color: t.success.value,
            title: 'Best month',
            value: bestMonth != null
                ? formatCurrency(bestMonth.revenue, currency)
                : 'No revenue recorded',
            subtitle: bestMonth != null
                ? monthName(bestMonth.month.toInt())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _planPerformance(
    ThemeTokens t,
    String currency,
    List<ReportsResponsePlanPerformanceInner> entries,
  ) {
    if (entries.isEmpty) {
      return AppSurface(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No plan performance yet',
          style: TextStyle(fontSize: 14, color: t.muted.foreground),
        ),
      );
    }

    num maxRevenue = 0;
    for (final ReportsResponsePlanPerformanceInner e in entries) {
      if (e.revenue > maxRevenue) maxRevenue = e.revenue;
    }

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.55),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          for (final ReportsResponsePlanPerformanceInner entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PlanPerformanceRow(
                tokens: t,
                currency: currency,
                entry: entry,
                maxRevenue: maxRevenue,
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentMethods(
    ThemeTokens t,
    String currency,
    List<ReportsResponsePaymentMethodsInner> methods,
  ) {
    if (methods.isEmpty) {
      return AppSurface(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No payment data yet',
          style: TextStyle(fontSize: 14, color: t.muted.foreground),
        ),
      );
    }

    final List<Color> palette = <Color>[
      t.primary.value,
      t.success.value,
      t.warning.value,
      t.accent.foreground,
      t.muted.foreground,
    ];

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.55),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < methods.length; i++)
                Expanded(
                  flex: _barFlex(methods[i].percentage),
                  child: Container(
                    height: 8,
                    color: palette[i % palette.length],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < methods.length; i++)
            _PaymentMethodRow(
              color: palette[i % palette.length],
              label: _methodLabels[methods[i].method] ?? methods[i].method,
              sub: '${methods[i].count.toInt()} transaction(s) · '
                  '${methods[i].percentage.round()}%',
              amount: formatCurrency(methods[i].amount, currency),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildLoading(ThemeTokens t) {
    return <Widget>[
      Container(
        height: 208,
        decoration: BoxDecoration(
          color: withOpacity(t.foreground, 0.08),
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      const SizedBox(height: 24),
      Container(
        height: 128,
        decoration: BoxDecoration(
          color: withOpacity(t.foreground, 0.08),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        height: 256,
        decoration: BoxDecoration(
          color: withOpacity(t.foreground, 0.08),
          borderRadius: BorderRadius.circular(28),
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
              "Couldn't load reports",
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
              onPressed: () => ref.invalidate(reportsProvider(_year)),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ];
  }
}

// -- collected hero -----------------------------------------------------------

class _CollectedHero extends StatelessWidget {
  const _CollectedHero({
    required this.tokens,
    required this.currency,
    required this.year,
    required this.summary,
  });

  final ThemeTokens tokens;
  final String currency;
  final int year;
  final ReportsResponseSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final Color labelColor = withOpacity(t.primary.foreground, 0.70);
    final num? change = summary.revenue.changePercent;

    return AppSurface(
      color: t.primary.value,
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
                      'Collected in $year',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(summary.revenue.value, currency),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05 * 32,
                        height: 1,
                        color: t.primary.foreground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ChangePill(
                      tokens: t,
                      previousYear: year - 1,
                      changePercent: change,
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: withOpacity(t.primary.foreground, 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.attach_money,
                  size: 24,
                  color: t.primary.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              _ReportHeroStat(
                value: summary.activeMembers.toInt().toString(),
                label: 'Active now',
                valueColor: t.primary.foreground,
                labelColor: labelColor,
              ),
              Container(
                width: 1,
                height: 32,
                color: withOpacity(t.primary.foreground, 0.15),
              ),
              _ReportHeroStat(
                value: formatCurrency(summary.outstandingDues, currency),
                label: 'Outstanding now',
                valueColor: t.primary.foreground,
                labelColor: labelColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({
    required this.tokens,
    required this.previousYear,
    this.changePercent,
  });

  final ThemeTokens tokens;
  final int previousYear;
  final num? changePercent;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final num? change = changePercent;

    final String label;
    final IconData? icon;
    if (change == null) {
      label = 'New vs $previousYear';
      icon = null;
    } else if (change == 0) {
      label = 'No change';
      icon = null;
    } else {
      label = '${_formatPercent(change)}%';
      icon = change > 0 ? Icons.arrow_upward : Icons.arrow_downward;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: withOpacity(t.primary.foreground, 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: t.primary.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.primary.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportHeroStat extends StatelessWidget {
  const _ReportHeroStat({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.labelColor,
  });

  final String value;
  final String label;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
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

// -- glance metric card -------------------------------------------------------

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.detail,
    this.changePercent,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? detail;
  final num? changePercent;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    final num? change = changePercent;

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.33),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: withOpacity(color, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: t.foreground,
            ),
          ),
          if (change != null) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (change > 0) ...<Widget>[
                  Icon(Icons.arrow_upward, size: 12, color: t.success.value),
                  const SizedBox(width: 2),
                ] else if (change < 0) ...<Widget>[
                  Icon(
                    Icons.arrow_downward,
                    size: 12,
                    color: t.destructive.value,
                  ),
                  const SizedBox(width: 2),
                ],
                Text(
                  '${_formatPercent(change)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: change > 0
                        ? t.success.value
                        : (change < 0
                            ? t.destructive.value
                            : t.muted.foreground),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: t.muted.foreground),
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.warning.value,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -- member health row --------------------------------------------------------

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: withOpacity(color, 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.foreground,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: t.muted.foreground),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.foreground,
              ),
            ),
            if (onTap != null) ...<Widget>[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: t.muted.foreground),
            ],
          ],
        ),
      ),
    );
  }
}

// -- plan performance row -----------------------------------------------------

class _PlanPerformanceRow extends StatelessWidget {
  const _PlanPerformanceRow({
    required this.tokens,
    required this.currency,
    required this.entry,
    required this.maxRevenue,
  });

  final ThemeTokens tokens;
  final String currency;
  final ReportsResponsePlanPerformanceInner entry;
  final num maxRevenue;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final double fraction =
        maxRevenue <= 0 ? 0 : (entry.revenue / maxRevenue).toDouble();

    return Column(
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
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.sales.toInt()} sale(s) · '
                    '${entry.activeMembers.toInt()} active now',
                    style: TextStyle(fontSize: 12, color: t.muted.foreground),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCurrency(entry.revenue, currency),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.foreground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: withOpacity(t.muted.value, 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: t.primary.value,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -- payment method row -------------------------------------------------------

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.color,
    required this.label,
    required this.sub,
    required this.amount,
  });

  final Color color;
  final String label;
  final String sub;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
