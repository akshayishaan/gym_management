import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../gym/application/active_gym_controller.dart';
import '../domain/activity_log.dart';
import '../domain/activity_log_query.dart';

/// Network access for the Activity Log feature. The controller lives in
/// `backend/src/activity/activity.controller.ts` and is scoped to the
/// selected gym via `RequireGymGuard` (the `X-Selected-Gym` header is
/// attached by `dio_client.dart`).
class ActivityRepository {
  ActivityRepository(this._dio);
  final Dio _dio;

  /// GET /activity?page=&limit=
  ///
  /// The backend ignores any `action` query param and always returns the
  /// full page sorted by `createdAt: -1`. Filtering by action is done
  /// client-side in the UI so the chip cluster can toggle without a
  /// round-trip.
  Future<ActivityLogPage> getLogs(ActivityLogQuery query) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/activity',
        queryParameters: {
          'page': query.page,
          'limit': query.limit,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data!;
        final list = (data['logs'] as List?) ?? const [];
        return ActivityLogPage(
          logs: list
              .whereType<Map<String, dynamic>>()
              .map(ActivityLog.fromJson)
              .toList(),
          total: (data['total'] as num?)?.toInt() ?? list.length,
          page: (data['page'] as num?)?.toInt() ?? query.page,
          limit: (data['limit'] as num?)?.toInt() ?? query.limit,
        );
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Object _badResponse(Response res) {
    return DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
    );
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(dioProvider));
});

/// Paginated activity log for the active gym. Re-runs when the active
/// gym changes so switching tenants refreshes the audit feed.
final activityLogProvider =
    FutureProvider.autoDispose.family<ActivityLogPage, ActivityLogQuery>(
  (ref, query) {
    ref.watch(activeGymProvider);
    return ref.watch(activityRepositoryProvider).getLogs(query);
  },
);