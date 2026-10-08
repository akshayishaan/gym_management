/// Immutable filter/pagination shape used as the family argument for
/// `memberListProvider`. The list screen passes a copy with new
/// search/status/page fields whenever the user changes filters.
class MemberListQuery {
  const MemberListQuery({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  /// Free-text search matched against name/phone/email on the backend.
  final String? search;

  /// Filter value. Accepted values (mirroring the backend `status` query
  /// param in `member.service.ts`):
  ///   * 'active' — expiry >= today
  ///   * 'expired' — expiry < today
  ///   * 'expiring' — expiry within 7 days
  ///   * 'expiring30' — expiry within 30 days
  ///   * 'due' — dueAmount > 0
  ///   * null — no status filter
  final String? status;

  final int page;
  final int limit;

  MemberListQuery copyWith({
    Object? search = _kSentinel,
    Object? status = _kSentinel,
    int? page,
    int? limit,
  }) {
    return MemberListQuery(
      search: identical(search, _kSentinel) ? this.search : search as String?,
      status: identical(status, _kSentinel) ? this.status : status as String?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberListQuery &&
        other.search == search &&
        other.status == status &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(search, status, page, limit);
}

const Object _kSentinel = Object();
