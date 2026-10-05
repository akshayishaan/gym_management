import 'activity_log.dart';

/// Immutable filter/pagination shape used as the family argument for
/// `activityLogProvider`. The list screen passes a copy whenever the
/// user toggles a chip or scrolls a page.
///
/// The backend's `ActivityService.list` only accepts `page` and `limit`
/// (no `action` query param). Filtering by action is therefore done
/// client-side after fetch in Track B's UI.
class ActivityLogQuery {
  const ActivityLogQuery({
    this.actions,
    this.page = 1,
    this.limit = 50,
  });

  /// Selected action chips (e.g. `{created, voided}`). Null/empty means
  /// "all actions".
  final Set<String>? actions;

  final int page;
  final int limit;

  ActivityLogQuery copyWith({
    Set<String>? actions,
    int? page,
    int? limit,
  }) {
    return ActivityLogQuery(
      actions: actions ?? this.actions,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ActivityLogQuery) return false;
    if (other.page != page) return false;
    if (other.limit != limit) return false;
    if (_setEquals(other.actions, actions)) return true;
    return false;
  }

  @override
  int get hashCode {
    final sorted = actions?.toList() ?? <String>[];
    sorted.sort();
    return Object.hash(Object.hashAll(sorted), page, limit);
  }

  static bool _setEquals(Set<String>? a, Set<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

/// Result envelope for `GET /activity`. The backend returns
/// `{ logs, total, page, limit }` — kept in 1:1 shape here so Track B's
/// list view can read both the page and the cumulative total.
class ActivityLogPage {
  const ActivityLogPage({
    required this.logs,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<ActivityLog> logs;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}