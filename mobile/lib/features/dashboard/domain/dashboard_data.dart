/// Dashboard summary as returned by `GET /dashboard`. Mirrors
/// `backend/src/dashboard/dashboard.service.ts#getDashboard`.
class DashboardData {
  const DashboardData({
    required this.totalMembers,
    required this.activeMembers,
    required this.expiredMembers,
    required this.expiringMembers,
    required this.monthRevenue,
    required this.recentPayments,
    required this.expiringList,
    this.monthRevenueDeltaPct,
    this.isRevenueDeltaSynthetic = false,
  });

  /// Total members with `isActive != false` (legacy docs count too).
  final int totalMembers;

  /// Members whose membershipExpiry >= today.
  final int activeMembers;

  /// Members whose membershipExpiry < today but still active.
  final int expiredMembers;

  /// Members expiring in the next 7 days.
  final int expiringMembers;

  /// Month-to-date revenue: paid this month − refunds this month.
  final double monthRevenue;

  /// Up to 5 most recent paid payments.
  final List<RecentPayment> recentPayments;

  /// Up to 10 members whose memberships expire within 7 days, sorted by
  /// nearest expiry. Each entry carries the days-until-expiry.
  final List<ExpiringMember> expiringList;

  /// Month-over-month revenue delta as a percentage (e.g. `12.4` means
  /// +12.4% vs the previous month). The backend doesn't ship this value
  /// yet, so the repository derives a stable synthetic value from the
  /// current month's revenue and marks it with [isRevenueDeltaSynthetic]
  /// so the UI can flag it as "Demo data".
  final double? monthRevenueDeltaPct;

  /// True when [monthRevenueDeltaPct] was synthesized client-side rather
  /// than returned by the backend. The UI should render the chip at a
  /// reduced opacity with a "Demo data" tooltip in that case.
  final bool isRevenueDeltaSynthetic;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      expiredMembers: (json['expiredMembers'] as num?)?.toInt() ?? 0,
      expiringMembers: (json['expiringMembers'] as num?)?.toInt() ?? 0,
      monthRevenue: (json['monthRevenue'] as num?)?.toDouble() ?? 0.0,
      recentPayments: ((json['recentPayments'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecentPayment.fromJson)
          .toList(),
      expiringList: ((json['expiringList'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ExpiringMember.fromJson)
          .toList(),
      monthRevenueDeltaPct:
          (json['monthRevenueDeltaPct'] as num?)?.toDouble(),
      isRevenueDeltaSynthetic:
          json['isRevenueDeltaSynthetic'] as bool? ?? false,
    );
  }
}

class RecentPayment {
  const RecentPayment({
    required this.id,
    required this.memberName,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.kind,
  });

  final String id;
  final String memberName;
  final double amount;
  final String method; // "cash" | "card" | "upi" | "bank_transfer" | "other"
  final DateTime paidAt;
  final String? kind; // "plan_purchase" | "dues"

  factory RecentPayment.fromJson(Map<String, dynamic> json) {
    return RecentPayment(
      id: (json['_id'] ?? json['id']) as String,
      memberName: json['memberName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method'] as String? ?? 'other',
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? '') ??
          DateTime.now(),
      kind: json['kind'] as String?,
    );
  }
}

class ExpiringMember {
  const ExpiringMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.membershipExpiry,
    required this.planName,
    required this.daysUntilExpiry,
  });

  final String id;
  final String name;
  final String? phone;
  /// YYYY-MM-DD string per the gym's authoritative timezone.
  final String membershipExpiry;
  final String? planName;
  /// Computed server-side; negative if already expired.
  final int daysUntilExpiry;

  factory ExpiringMember.fromJson(Map<String, dynamic> json) {
    return ExpiringMember(
      id: (json['_id'] ?? json['id']) as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      membershipExpiry: json['membershipExpiry'] as String? ?? '',
      planName: json['planName'] as String?,
      daysUntilExpiry: (json['daysUntilExpiry'] as num?)?.toInt() ?? 0,
    );
  }
}