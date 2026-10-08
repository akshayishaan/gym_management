/// Dart models for the response from `GET /reports?year=YYYY`. The
/// backend's `reportTypes.ts` is the source of truth; these mirror it
/// 1:1 with camelCase fields and hand-written `fromJson` factories.
///
/// Kept as plain Dart classes (no freezed/json_serializable) to match
/// `Payment`/`Member`/`Plan`/`ActivityLog`.
class ReportComparisonMetric {
  const ReportComparisonMetric({
    required this.value,
    required this.previous,
    this.changePercent,
  });

  /// Current-period value (e.g. revenue, transactions, newMembers,
  /// renewals) for the requested year.
  final double value;

  /// Previous-year value for the same metric. Used to compute the
  /// delta badge in the summary row.
  final double previous;

  /// Null when the previous period was zero (undefined percent change).
  final double? changePercent;

  /// Formatted chip label. `'—'` for the null case, signed for non-zero
  /// deltas. Returns `'0.0%'` when the value is exactly equal to
  /// previous (no rounding noise).
  String get changePercentLabel {
    final pct = changePercent;
    if (pct == null) return '—';
    final rounded = (pct * 10).round() / 10;
    if (rounded == 0) return '0.0%';
    final sign = rounded > 0 ? '+' : '';
    return '$sign$rounded%';
  }

  factory ReportComparisonMetric.fromJson(Map<String, dynamic> json) {
    return ReportComparisonMetric(
      value: (json['value'] as num?)?.toDouble() ?? 0,
      previous: (json['previous'] as num?)?.toDouble() ?? 0,
      changePercent: (json['changePercent'] as num?)?.toDouble(),
    );
  }
}

class ReportSeriesPoint {
  const ReportSeriesPoint({
    required this.month,
    required this.revenue,
    required this.transactions,
    required this.newMembers,
    required this.memberships,
    required this.renewals,
  });

  final int month;
  final double revenue;
  final int transactions;
  final int newMembers;
  final int memberships;
  final int renewals;

  /// Single-letter month label for the chart axis: Jan→'J', Feb→'F', etc.
  String get monthShort {
    const labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final idx = month - 1;
    if (idx < 0 || idx >= labels.length) return '?';
    return labels[idx];
  }

  factory ReportSeriesPoint.fromJson(Map<String, dynamic> json) {
    return ReportSeriesPoint(
      month: (json['month'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      transactions: (json['transactions'] as num?)?.toInt() ?? 0,
      newMembers: (json['newMembers'] as num?)?.toInt() ?? 0,
      memberships: (json['memberships'] as num?)?.toInt() ?? 0,
      renewals: (json['renewals'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReportPlanPerformance {
  const ReportPlanPerformance({
    required this.key,
    this.planId,
    required this.name,
    required this.revenue,
    required this.sales,
    required this.activeMembers,
  });

  /// Aggregation key — typically the plan id, or `__unassigned__` for
  /// dues-only payments.
  final String key;
  final String? planId;
  final String name;
  final double revenue;
  final int sales;
  final int activeMembers;

  factory ReportPlanPerformance.fromJson(Map<String, dynamic> json) {
    return ReportPlanPerformance(
      key: json['key'] as String? ?? '',
      planId: json['planId']?.toString(),
      name: json['name'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      sales: (json['sales'] as num?)?.toInt() ?? 0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReportPaymentMethod {
  const ReportPaymentMethod({
    required this.method,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  final String method;
  final double amount;
  final int count;
  final double percentage;

  factory ReportPaymentMethod.fromJson(Map<String, dynamic> json) {
    return ReportPaymentMethod(
      method: json['method'] as String? ?? 'other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReportSummary {
  const ReportSummary({
    required this.revenue,
    required this.transactions,
    required this.newMembers,
    required this.renewals,
    required this.activeMembers,
    required this.outstandingDues,
    required this.dueMembers,
  });

  final ReportComparisonMetric revenue;
  final ReportComparisonMetric transactions;
  final ReportComparisonMetric newMembers;
  final ReportComparisonMetric renewals;
  final int activeMembers;
  final double outstandingDues;
  final int dueMembers;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      revenue: ReportComparisonMetric.fromJson(
        (json['revenue'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      transactions: ReportComparisonMetric.fromJson(
        (json['transactions'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      newMembers: ReportComparisonMetric.fromJson(
        (json['newMembers'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      renewals: ReportComparisonMetric.fromJson(
        (json['renewals'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      outstandingDues: (json['outstandingDues'] as num?)?.toDouble() ?? 0,
      dueMembers: (json['dueMembers'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReportBestMonth {
  const ReportBestMonth({required this.month, required this.revenue});

  final int month;
  final double revenue;

  factory ReportBestMonth.fromJson(Map<String, dynamic> json) {
    return ReportBestMonth(
      month: (json['month'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReportInsights {
  const ReportInsights({
    required this.expiringSoon,
    required this.expiredMembers,
    required this.dueMembers,
    required this.outstandingDues,
    this.bestMonth,
  });

  final int expiringSoon;
  final int expiredMembers;
  final int dueMembers;
  final double outstandingDues;
  final ReportBestMonth? bestMonth;

  factory ReportInsights.fromJson(Map<String, dynamic> json) {
    final bestMonthRaw = json['bestMonth'];
    return ReportInsights(
      expiringSoon: (json['expiringSoon'] as num?)?.toInt() ?? 0,
      expiredMembers: (json['expiredMembers'] as num?)?.toInt() ?? 0,
      dueMembers: (json['dueMembers'] as num?)?.toInt() ?? 0,
      outstandingDues: (json['outstandingDues'] as num?)?.toDouble() ?? 0,
      bestMonth: bestMonthRaw is Map
          ? ReportBestMonth.fromJson(bestMonthRaw.cast<String, dynamic>())
          : null,
    );
  }
}

class ReportsResponse {
  const ReportsResponse({
    required this.year,
    required this.asOf,
    required this.timezone,
    required this.summary,
    required this.series,
    required this.planPerformance,
    required this.paymentMethods,
    required this.insights,
  });

  final int year;
  final String asOf;
  final String timezone;
  final ReportSummary summary;
  final List<ReportSeriesPoint> series;
  final List<ReportPlanPerformance> planPerformance;
  final List<ReportPaymentMethod> paymentMethods;
  final ReportInsights insights;

  factory ReportsResponse.fromJson(Map<String, dynamic> json) {
    return ReportsResponse(
      year: (json['year'] as num?)?.toInt() ?? 0,
      asOf: json['asOf'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
      summary: ReportSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      series: ((json['series'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => ReportSeriesPoint.fromJson(m.cast<String, dynamic>()))
          .toList(),
      planPerformance: ((json['planPerformance'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => ReportPlanPerformance.fromJson(m.cast<String, dynamic>()))
          .toList(),
      paymentMethods: ((json['paymentMethods'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => ReportPaymentMethod.fromJson(m.cast<String, dynamic>()))
          .toList(),
      insights: ReportInsights.fromJson(
        (json['insights'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }
}