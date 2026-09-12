import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/dio_providers.dart';
import '../core/api/error_interceptor.dart';
import 'api_helpers.dart';

/// The authenticated user's gyms, as a bare JSON array (not wrapped).
///
/// This is a JWT-scoped endpoint — no `X-Selected-Gym` header is required — so
/// it is not part of [invalidateGymScope] and does not touch the per-gym
/// last-fetch registry.
final gymsProvider = FutureProvider.autoDispose<List<GymResponse>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final Response<dynamic> res = await dio.get<dynamic>('/gyms');
    final List<dynamic> data = decodeJsonList(res);
    return data
        .map(
          (dynamic item) => GymResponse.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  } catch (e) {
    // Normalize every failure — transport (DioException) or a mismatched body
    // (TypeError/FormatException) — to an ApiException.
    throw asApiException(e);
  }
});
