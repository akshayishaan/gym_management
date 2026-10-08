import 'activity_log.dart';

/// Immutable filter/pagination shape used as the family argument for
/// `activityLogProvider`.
///
/// All filtering happens on the server, in the Gym's own calendar:
///  * [range] is `today`, `week` or null (no date filter);
///  * [from]/[to] are inclusive `YYYY-MM-DD` dates for a custom range;
///  * [actions] limits results to those action names.
class ActivityLogQuery {
  const ActivityLogQuery({
    this.actions,
    this.range,
    this.from,
    this.to,
    this.page = 1,
    this.limit = 50,
  });

  final Set<String>? actions;
  final String? range;
  final String? from;
  final String? to;
  final int page;
  final int limit;

  /// Identifies the filter without the page size, so the screen can tell
  /// "same filter, more rows" (Load More) from "different filter".
  String get filterKey {
    final sorted = (actions ?? const <String>{}).toList()..sort();
    return '${range ?? ''}|${from ?? ''}|${to ?? ''}|${sorted.join(',')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityLogQuery &&
        other.page == page &&
        other.limit == limit &&
        other.filterKey == filterKey;
  }

  @override
  int get hashCode => Object.hash(filterKey, page, limit);
}

/// Result envelope for `GET /activity`: the page of logs, the server's
/// total for the same filter, and the Gym's current calendar date.
class ActivityLogPage {
  const ActivityLogPage({
    required this.logs,
    required this.total,
    required this.page,
    required this.limit,
    this.today,
  });

  final List<ActivityLog> logs;
  final int total;
  final int page;
  final int limit;

  /// The Gym's current date (`YYYY-MM-DD`), from the server.
  final String? today;

  bool get hasMore => page * limit < total;
}
