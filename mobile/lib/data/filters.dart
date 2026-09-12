/// Sentinel distinguishing "leave unchanged" from "set to null" in [copyWith]
/// for the nullable filter fields.
const Object _unset = Object();

/// Immutable filters for the members list endpoint.
class MemberFilters {
  const MemberFilters({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  final String? search;
  final String? status;
  final int page;
  final int limit;

  MemberFilters copyWith({
    Object? search = _unset,
    Object? status = _unset,
    int? page,
    int? limit,
  }) {
    return MemberFilters(
      search: identical(search, _unset) ? this.search : search as String?,
      status: identical(status, _unset) ? this.status : status as String?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberFilters &&
        other.search == search &&
        other.status == status &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(search, status, page, limit);
}

/// Immutable filters for the payments list endpoint.
class PaymentFilters {
  const PaymentFilters({
    this.memberId,
    this.month,
    this.page = 1,
    this.limit = 20,
  });

  final String? memberId;
  final String? month;
  final int page;
  final int limit;

  PaymentFilters copyWith({
    Object? memberId = _unset,
    Object? month = _unset,
    int? page,
    int? limit,
  }) {
    return PaymentFilters(
      memberId:
          identical(memberId, _unset) ? this.memberId : memberId as String?,
      month: identical(month, _unset) ? this.month : month as String?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentFilters &&
        other.memberId == memberId &&
        other.month == month &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(memberId, month, page, limit);
}

/// Immutable filters for the plans list endpoint.
class PlanFilters {
  const PlanFilters({
    this.search,
    this.status = 'active',
    this.page = 1,
    this.limit = 50,
    this.includeStats = true,
  });

  final String? search;

  /// `active`, `inactive`, or `all` (null means "all" — the backend defaults
  /// to `all` when the param is omitted).
  final String? status;
  final int page;
  final int limit;
  final bool includeStats;

  PlanFilters copyWith({
    Object? search = _unset,
    Object? status = _unset,
    int? page,
    int? limit,
    bool? includeStats,
  }) {
    return PlanFilters(
      search: identical(search, _unset) ? this.search : search as String?,
      status: identical(status, _unset) ? this.status : status as String?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      includeStats: includeStats ?? this.includeStats,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlanFilters &&
        other.search == search &&
        other.status == status &&
        other.page == page &&
        other.limit == limit &&
        other.includeStats == includeStats;
  }

  @override
  int get hashCode => Object.hash(search, status, page, limit, includeStats);
}

/// Immutable filters for the activity log endpoint.
class ActivityFilters {
  const ActivityFilters({this.page = 1, this.limit = 50});

  final int page;
  final int limit;

  ActivityFilters copyWith({int? page, int? limit}) {
    return ActivityFilters(
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActivityFilters &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(page, limit);
}
