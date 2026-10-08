import 'plan.dart';

/// Result envelope for the paginated `GET /plans` response. Mirrors the
/// backend's `PlansResponse` in `backend/src/lib/planTypes.ts`.
class PlansResponse {
  const PlansResponse({
    required this.plans,
    required this.total,
    required this.page,
    required this.limit,
    this.summary,
    this.counts,
  });

  final List<Plan> plans;
  final int total;
  final int page;
  final int limit;

  /// Gym-wide portfolio summary attached when `includeStats=true` (the
  /// default). The list screen reads this for the KPI card.
  final PlansSummary? summary;

  /// Gym-wide plan counts for the filter pills (not affected by filters).
  final PlanCounts? counts;

  bool get hasMore => page * limit < total;
}

/// All / active / paused plan counts for the whole gym.
class PlanCounts {
  const PlanCounts({this.all = 0, this.active = 0, this.inactive = 0});

  final int all;
  final int active;
  final int inactive;

  factory PlanCounts.fromJson(Map<String, dynamic> json) => PlanCounts(
    all: (json['all'] as num?)?.toInt() ?? 0,
    active: (json['active'] as num?)?.toInt() ?? 0,
    inactive: (json['inactive'] as num?)?.toInt() ?? 0,
  );
}

/// Portfolio roll-up returned alongside the plan list. Mirrors the
/// backend's `summary` field in `PlansResponse`.
class PlansSummary {
  const PlansSummary({
    this.activePlans = 0,
    this.activeMembers = 0,
    this.salesYtd = 0,
    this.revenueAtSaleYtd = 0,
  });

  final int activePlans;
  final int activeMembers;
  final int salesYtd;
  final double revenueAtSaleYtd;

  factory PlansSummary.fromJson(Map<String, dynamic> json) {
    return PlansSummary(
      activePlans: (json['activePlans'] as num?)?.toInt() ?? 0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      salesYtd: (json['salesYtd'] as num?)?.toInt() ?? 0,
      revenueAtSaleYtd: (json['revenueAtSaleYtd'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Immutable filter/pagination shape used as the family argument for
/// `planListProvider`. The list screen passes a copy with new
/// search/status/page fields whenever the user changes filters.
class PlanListQuery {
  const PlanListQuery({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 50,
  });

  /// Free-text search matched against `name` on the backend (partial,
  /// case-insensitive — see `partialPlanNamePattern` in
  /// `backend/src/lib/planUtils.ts`).
  final String? search;

  /// Filter value. Accepted values (mirroring the backend `status`
  /// query param in `plan.service.ts`):
  ///   * 'active' — `isActive` is not false
  ///   * 'inactive' — `isActive === false`
  ///   * 'all' / null — no status filter
  final String? status;

  final int page;
  final int limit;

  PlanListQuery copyWith({
    Object? search = _kSentinel,
    Object? status = _kSentinel,
    int? page,
    int? limit,
  }) {
    return PlanListQuery(
      search: identical(search, _kSentinel) ? this.search : search as String?,
      status: identical(status, _kSentinel) ? this.status : status as String?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanListQuery &&
        other.search == search &&
        other.status == status &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(search, status, page, limit);
}

const Object _kSentinel = Object();
