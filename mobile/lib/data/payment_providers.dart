import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/dio_providers.dart';
import 'api_helpers.dart';
import 'filters.dart';
import 'query_scope.dart';

/// The paginated payment list for the selected gym, filtered by
/// [PaymentFilters].
final paymentsProvider = FutureProvider.autoDispose
    .family<PaymentListResponse, PaymentFilters>(
        (ref, PaymentFilters filters) async {
  ref.watch(appResumeTickProvider);
  final String? gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) throw StateError('No gym selected');

  final Map<String, dynamic> query = <String, dynamic>{
    'page': filters.page,
    'limit': filters.limit,
  };
  if (filters.memberId != null && filters.memberId!.isNotEmpty) {
    query['memberId'] = filters.memberId;
  }
  if (filters.month != null && filters.month!.isNotEmpty) {
    query['month'] = filters.month;
  }

  final dio = ref.watch(dioProvider);
  final PaymentListResponse result = await getJson<PaymentListResponse>(
    dio,
    '/payments',
    query: query,
    fromJson: PaymentListResponse.fromJson,
  );
  ref.read(scopeLastFetchProvider.notifier).touch(gymId);
  return result;
});

/// A single, full payment by id (used by the invoice screen).
final paymentProvider = FutureProvider.autoDispose
    .family<PaymentResponse, String>((ref, String paymentId) async {
  ref.watch(appResumeTickProvider);
  final String? gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) throw StateError('No gym selected');

  final dio = ref.watch(dioProvider);
  final PaymentResponse result = await getJson<PaymentResponse>(
    dio,
    '/payments/$paymentId',
    fromJson: PaymentResponse.fromJson,
  );
  ref.read(scopeLastFetchProvider.notifier).touch(gymId);
  return result;
});
