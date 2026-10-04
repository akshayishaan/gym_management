import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../gym/application/active_gym_controller.dart';
import '../domain/dashboard_data.dart';

class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  /// GET /dashboard — gym-scoped summary.
  Future<DashboardData> getDashboard() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard');
      if (res.statusCode == 200 && res.data != null) {
        return DashboardData.fromJson(res.data!);
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

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

/// Live dashboard for the active gym. Re-runs when the active-gym provider
/// emits a new value, so switching gyms refreshes the data automatically.
final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  // Watch the active gym so we refetch when the user switches.
  ref.watch(activeGymProvider);
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});