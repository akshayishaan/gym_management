import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/dio_providers.dart';
import 'api_helpers.dart';
import 'filters.dart';
import 'query_scope.dart';

/// The paginated plan list for the selected gym, filtered by [PlanFilters].
final plansProvider = FutureProvider.autoDispose
    .family<PlanListResponse, PlanFilters>((ref, PlanFilters filters) async {
  ref.watch(appResumeTickProvider);
  final String? gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) throw StateError('No gym selected');

  final Map<String, dynamic> query = <String, dynamic>{
    'page': filters.page,
    'limit': filters.limit,
    'includeStats': filters.includeStats,
  };
  if (filters.search != null && filters.search!.isNotEmpty) {
    query['search'] = filters.search;
  }
  if (filters.status != null && filters.status!.isNotEmpty) {
    query['status'] = filters.status;
  }

  final dio = ref.watch(dioProvider);
  final PlanListResponse result = await getJson<PlanListResponse>(
    dio,
    '/plans',
    query: query,
    fromJson: PlanListResponse.fromJson,
  );
  ref.read(scopeLastFetchProvider.notifier).touch(gymId);
  return result;
});
