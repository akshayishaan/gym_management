import '../../../core/utils/money.dart';

/// A RepiX Membership Plan as returned by `GET /plans`, `POST /plans`,
/// and `PUT /plans/:id`. The backend's `plan.schema.ts` is the source
/// of truth; this model mirrors it with camelCase Dart fields.
///
/// Kept as a plain Dart class (no freezed) to match the project's
/// existing `Member` style and avoid pulling freezed codegen into a repo
/// that doesn't currently use it.
class Plan {
  const Plan({
    required this.id,
    required this.gymId,
    required this.name,
    this.description,
    required this.durationDays,
    required this.price,
    this.features = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.stats,
  });

  /// Mongoose `_id` mapped to `id` on the wire.
  final String id;
  final String gymId;
  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final List<String> features;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Inline stats attached by the backend when `includeStats=true`
  /// (the default). `activeMembers`, `salesYtd`, `totalMemberships`
  /// are integer counts; `revenueAtSaleYtd` is currency in the gym's
  /// denomination (dollars in the demo).
  final PlanStats? stats;

  /// `₹1,499.50` style label used on the plan card and form sheet. Whole
  /// prices drop the decimals (`₹1,500`). Indian digit grouping.
  String get formattedPrice =>
      formatInr(price, decimals: price % 1 == 0 ? 0 : 2);

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: (json['_id'] ?? json['id']).toString(),
      gymId: (json['gymId'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      features: ((json['features'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      stats: json['stats'] is Map
          ? PlanStats.fromJson((json['stats'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

/// Aggregate counters attached to each [Plan] by the backend. The
/// `PlanStats` factory defaults every field to 0 so a partially-populated
/// payload (older backend, or a plan with no memberships) doesn't trip
/// NPEs in the UI.
class PlanStats {
  const PlanStats({
    this.activeMembers = 0,
    this.salesYtd = 0,
    this.revenueAtSaleYtd = 0,
    this.totalMemberships = 0,
  });

  final int activeMembers;
  final int salesYtd;
  final double revenueAtSaleYtd;
  final int totalMemberships;

  factory PlanStats.fromJson(Map<String, dynamic> json) {
    return PlanStats(
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      salesYtd: (json['salesYtd'] as num?)?.toInt() ?? 0,
      revenueAtSaleYtd: (json['revenueAtSaleYtd'] as num?)?.toDouble() ?? 0,
      totalMemberships: (json['totalMemberships'] as num?)?.toInt() ?? 0,
    );
  }
}
