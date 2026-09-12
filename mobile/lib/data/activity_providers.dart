import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/dio_providers.dart';
import 'api_helpers.dart';
import 'filters.dart';
import 'query_scope.dart';

/// The paginated activity log for the selected gym, filtered by
/// [ActivityFilters].
final activityProvider = FutureProvider.autoDispose
    .family<ActivityListResponse, ActivityFilters>(
        (ref, ActivityFilters filters) async {
  ref.watch(appResumeTickProvider);
  final String? gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) throw StateError('No gym selected');

  final Map<String, dynamic> query = <String, dynamic>{
    'page': filters.page,
    'limit': filters.limit,
  };

  final dio = ref.watch(dioProvider);
  final ActivityListResponse result = await getJson<ActivityListResponse>(
    dio,
    '/activity',
    query: query,
    fromJson: ActivityListResponse.fromJson,
  );
  ref.read(scopeLastFetchProvider.notifier).touch(gymId);
  return result;
});
