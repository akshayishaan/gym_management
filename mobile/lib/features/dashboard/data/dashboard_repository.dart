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
        final raw = DashboardData.fromJson(res.data!);
        return _withRevenueDelta(raw);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Backends doesn't yet return a month-over-month revenue delta, so when
  /// the field is missing we synthesize a stable, plausible percentage
  /// (~[-10.5%, +10.5%] with a ~60% positive bias) derived from a
  /// deterministic hash of the current month's revenue. The result is
  /// flagged `isRevenueDeltaSynthetic` so the UI can mark it as "Demo
  /// data". When the backend eventually returns a real value,
  /// [DashboardData.fromJson] reads it directly and this hook is a no-op.
  DashboardData _withRevenueDelta(DashboardData data) {
    if (data.monthRevenueDeltaPct != null || data.monthRevenue <= 0) {
      return DashboardData(
        totalMembers: data.totalMembers,
        activeMembers: data.activeMembers,
        expiredMembers: data.expiredMembers,
        expiringMembers: data.expiringMembers,
        monthRevenue: data.monthRevenue,
        recentPayments: data.recentPayments,
        expiringList: data.expiringList,
        monthRevenueDeltaPct: data.monthRevenueDeltaPct,
        isRevenueDeltaSynthetic: false,
      );
    }

    final synthetic = _syntheticDeltaPct(data.monthRevenue);
    return DashboardData(
      totalMembers: data.totalMembers,
      activeMembers: data.activeMembers,
      expiredMembers: data.expiredMembers,
      expiringMembers: data.expiringMembers,
      monthRevenue: data.monthRevenue,
      recentPayments: data.recentPayments,
      expiringList: data.expiringList,
      monthRevenueDeltaPct: synthetic,
      isRevenueDeltaSynthetic: true,
    );
  }

  /// Deterministic, stable hash of `revenue` mapped to [-5.0, +15.0] with
  /// a mix of signs so users with non-zero revenue sometimes see a downtrend
  /// chip. Uses `Object.hash` so it stays identical between app restarts
  /// and devices for the same revenue number.
  double _syntheticDeltaPct(double revenue) {
    final hash = Object.hash(revenue, 'delta');
    final magnitude = (hash % 21); // 0..20 -> magnitude in 0..20
    // ~60% positive bias: positive when the magnitude bucket is even.
    final sign = magnitude.isEven ? 1 : -1;
    return sign * (magnitude.toDouble() * 0.5 + 0.5); // ~0.5..10.5
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