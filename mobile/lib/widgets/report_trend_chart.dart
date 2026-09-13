import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_api/gym_api.dart';

import '../data/formatters.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';

/// A 3-metric (Revenue / Members / Renewals) monthly area line chart, ported
/// from the web `ReportTrendChart`. Renders the selected metric over the 12
/// calendar months with a dashed horizontal grid, an area fill, and a touch
/// tooltip that names the month.
class ReportTrendChart extends StatefulWidget {
  const ReportTrendChart({
    super.key,
    required this.series,
    required this.currency,
  });

  final List<ReportsResponseSeriesInner> series;
  final String currency;

  @override
  State<ReportTrendChart> createState() => _ReportTrendChartState();
}

class _ReportTrendChartState extends State<ReportTrendChart> {
  int _metric = 0; // 0 = revenue, 1 = new members, 2 = renewals.

  num _valueFor(ReportsResponseSeriesInner s) => switch (_metric) {
        0 => s.revenue,
        1 => s.newMembers,
        _ => s.renewals,
      };

  Color _colorFor(ThemeTokens t) => switch (_metric) {
        0 => t.primary.value,
        1 => t.accent.value,
        _ => t.success.value,
      };

  String _labelFor(num value) => _metric == 0
      ? formatCurrency(value, widget.currency)
      : value.toInt().toString();

  String _monthShort(int month) => kMonthNames[month - 1].substring(0, 3);

  List<FlSpot> _spots() {
    final List<ReportsResponseSeriesInner> sorted =
        List<ReportsResponseSeriesInner>.from(widget.series)
          ..sort((ReportsResponseSeriesInner a, ReportsResponseSeriesInner b) =>
              a.month.compareTo(b.month));
    return sorted
        .map((ReportsResponseSeriesInner s) =>
            FlSpot(s.month.toDouble(), _valueFor(s).toDouble()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _segmented(t),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: widget.series.isEmpty
              ? Center(
                  child: Text(
                    'No data for this year',
                    style: TextStyle(fontSize: 13, color: t.muted.foreground),
                  ),
                )
              : _chart(t),
        ),
      ],
    );
  }

  Widget _segmented(ThemeTokens t) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.muted.value,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          _segment(t, 'Revenue', 0),
          _segment(t, 'Members', 1),
          _segment(t, 'Renewals', 2),
        ],
      ),
    );
  }

  Widget _segment(ThemeTokens t, String label, int value) {
    final bool selected = _metric == value;
    final Color foreground = selected ? t.background : t.muted.foreground;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _metric = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? t.foreground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chart(ThemeTokens t) {
    final Color color = _colorFor(t);
    final bool isRevenue = _metric == 0;
    final double? maxY = isRevenue ? null : _countMaxY();

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: 12,
        minY: 0,
        maxY: maxY,
        backgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (double value) => FlLine(
            color: withOpacity(t.border, 0.5),
            strokeWidth: 1,
            dashArray: const <int>[4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int month = value.toInt();
                if (month < 1 || month > 12) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _monthShort(month),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: t.muted.foreground,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) => t.card.value,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot spot) {
                final int month = spot.x.toInt();
                return LineTooltipItem(
                  '${_labelFor(spot.y)}\n${kMonthNames[month - 1]}',
                  TextStyle(
                    color: t.foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: _spots(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  withOpacity(color, 0.28),
                  withOpacity(color, 0.0),
                ],
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (
                FlSpot spot,
                double percent,
                LineChartBarData bar,
                int index,
              ) =>
                  FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: t.card.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _countMaxY() {
    num max = 0;
    for (final ReportsResponseSeriesInner s in widget.series) {
      if (_valueFor(s) > max) max = _valueFor(s);
    }
    return max <= 0 ? 1.0 : (max + 1).toDouble();
  }
}
