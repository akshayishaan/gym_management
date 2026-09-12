import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/dio_providers.dart';
import 'api_helpers.dart';
import 'query_scope.dart';

/// The (non-paginated) membership history for a member.
final membershipsProvider = FutureProvider.autoDispose
    .family<MembershipListResponse, String>((ref, String memberId) async {
  ref.watch(appResumeTickProvider);
  final String? gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) throw StateError('No gym selected');

  final dio = ref.watch(dioProvider);
  final MembershipListResponse result = await getJson<MembershipListResponse>(
    dio,
    '/memberships',
    query: <String, dynamic>{'memberId': memberId},
    fromJson: MembershipListResponse.fromJson,
  );
  ref.read(scopeLastFetchProvider.notifier).touch(gymId);
  return result;
});
