import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/dio_providers.dart';
import 'api_helpers.dart';
import 'filters.dart';
import 'query_scope.dart';

/// The paginated member list for the selected gym, filtered by [MemberFilters].
final membersProvider = FutureProvider.autoDispose
    .family<MemberListResponse, MemberFilters>(
        (ref, MemberFilters filters) async {
  ref.watch(appResumeTickProvider);
  final String? gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) throw StateError('No gym selected');

  final Map<String, dynamic> query = <String, dynamic>{
    'page': filters.page,
    'limit': filters.limit,
  };
  if (filters.search != null && filters.search!.isNotEmpty) {
    query['search'] = filters.search;
  }
  if (filters.status != null && filters.status!.isNotEmpty) {
    query['status'] = filters.status;
  }

  final dio = ref.watch(dioProvider);
  final MemberListResponse result = await getJson<MemberListResponse>(
    dio,
    '/members',
    query: query,
    fromJson: MemberListResponse.fromJson,
  );
  ref.read(scopeLastFetchProvider.notifier).touch(gymId);
  return result;
});

/// A single, full member by id.
final memberProvider = FutureProvider.autoDispose
    .family<MemberResponse, String>((ref, String memberId) async {
  ref.watch(appResumeTickProvider);
  final String? gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) throw StateError('No gym selected');

  final dio = ref.watch(dioProvider);
  final MemberResponse result = await getJson<MemberResponse>(
    dio,
    '/members/$memberId',
    fromJson: MemberResponse.fromJson,
  );
  ref.read(scopeLastFetchProvider.notifier).touch(gymId);
  return result;
});
