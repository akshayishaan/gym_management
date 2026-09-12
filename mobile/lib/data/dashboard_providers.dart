import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/dio_providers.dart';
import 'api_helpers.dart';
import 'query_scope.dart';

/// The dashboard summary for the selected gym.
final dashboardProvider = FutureProvider.autoDispose<DashboardResponse>(
  (ref) async {
    ref.watch(appResumeTickProvider);
    final String? gymId = ref.watch(selectedGymIdProvider);
    if (gymId == null) throw StateError('No gym selected');

    final dio = ref.watch(dioProvider);
    final DashboardResponse result = await getJson<DashboardResponse>(
      dio,
      '/dashboard',
      fromJson: DashboardResponse.fromJson,
    );
    ref.read(scopeLastFetchProvider.notifier).touch(gymId);
    return result;
  },
);
