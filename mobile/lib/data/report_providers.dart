import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/dio_providers.dart';
import 'api_helpers.dart';
import 'query_scope.dart';

/// The yearly reports for the selected gym.
final reportsProvider = FutureProvider.autoDispose
    .family<ReportsResponse, int>((ref, int year) async {
  ref.watch(appResumeTickProvider);
  final String? gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) throw StateError('No gym selected');

  final dio = ref.watch(dioProvider);
  final ReportsResponse result = await getJson<ReportsResponse>(
    dio,
    '/reports',
    query: <String, dynamic>{'year': year},
    fromJson: ReportsResponse.fromJson,
  );
  ref.read(scopeLastFetchProvider.notifier).touch(gymId);
  return result;
});
