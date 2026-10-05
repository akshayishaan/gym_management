import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../gym/application/active_gym_controller.dart';
import '../domain/report.dart';

/// Network access for the Reports feature. The controller lives in
/// `backend/src/reports/reports.controller.ts` and is scoped to the
/// selected gym via `RequireGymGuard` (the `X-Selected-Gym` header is
/// attached by `dio_client.dart`).
///
/// The backend's `ReportsService` coerces the year to an integer in
/// [2000..2100] or falls back to the current year for the Gym's timezone.
class ReportsRepository {
  ReportsRepository(this._dio);
  final Dio _dio;

  /// GET /reports?year=YYYY
  Future<ReportsResponse> getReport(int year) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/reports',
        queryParameters: {'year': year},
      );
      if (res.statusCode == 200 && res.data != null) {
        return ReportsResponse.fromJson(res.data!);
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

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(dioProvider));
});

/// Annual report for the active gym. The `family` key is the requested
/// year; switching tenants or paging back to a different year produces
/// a fresh fetch. Re-runs when [activeGymProvider] changes so tenant
/// switches invalidate the cached annual aggregate.
final reportsProvider =
    FutureProvider.autoDispose.family<ReportsResponse, int>((ref, year) {
  ref.watch(activeGymProvider);
  return ref.watch(reportsRepositoryProvider).getReport(year);
});