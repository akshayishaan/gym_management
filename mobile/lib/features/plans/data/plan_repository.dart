import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../gym/application/active_gym_controller.dart';
import '../domain/plan.dart';
import '../domain/plans_response.dart';

/// Plain Dart transport shape for `POST /plans`. Server validates with
/// `planCreateSchema` in `backend/src/plans/plan.schemas.ts`. All
/// fields except `name` are optional at the transport level so the
/// form sheet can send partial drafts if needed.
class PlanCreateInput {
  const PlanCreateInput({
    required this.name,
    required this.durationDays,
    required this.price,
    this.description,
    this.features,
    this.isActive = true,
  });

  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final List<String>? features;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null && description!.isNotEmpty)
      'description': description,
    'durationDays': durationDays,
    'price': price,
    if (features != null) 'features': features,
    'isActive': isActive,
  };
}

/// Plain Dart transport shape for `PUT /plans/:id`. Mirrors
/// `planUpdateSchema` — every field is optional.
class PlanUpdateInput {
  const PlanUpdateInput({
    this.name,
    this.description,
    this.durationDays,
    this.price,
    this.features,
    this.isActive,
  });

  final String? name;
  final String? description;
  final int? durationDays;
  final double? price;
  final List<String>? features;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (durationDays != null) 'durationDays': durationDays,
    if (price != null) 'price': price,
    if (features != null) 'features': features,
    if (isActive != null) 'isActive': isActive,
  };
}

/// Network access for the Plans feature. Routes live in
/// `backend/src/plans/plan.controller.ts` and are scoped to the
/// selected gym via `RequireGymGuard` (the `X-Selected-Gym` header is
/// attached by `dio_client.dart`).
///
/// There is no `GET /plans/:id` endpoint — the edit sheet is populated
/// from the cached `planListProvider` result, not from a per-id fetch.
class PlanRepository {
  PlanRepository(this._dio);
  final Dio _dio;

  /// GET /plans?search=&status=&page=&limit=&includeStats=true
  Future<PlansResponse> getPlans(PlanListQuery query) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/plans',
        queryParameters: {
          if (query.search != null && query.search!.isNotEmpty)
            'search': query.search,
          if (query.status != null && query.status!.isNotEmpty)
            'status': query.status,
          'page': query.page,
          'limit': query.limit,
          'includeStats': true,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data!;
        final list = (data['plans'] as List?) ?? const [];
        return PlansResponse(
          plans: list
              .whereType<Map<String, dynamic>>()
              .map(Plan.fromJson)
              .toList(),
          total: (data['total'] as num?)?.toInt() ?? list.length,
          page: (data['page'] as num?)?.toInt() ?? query.page,
          limit: (data['limit'] as num?)?.toInt() ?? query.limit,
          counts: data['counts'] is Map
              ? PlanCounts.fromJson(
                  (data['counts'] as Map).cast<String, dynamic>(),
                )
              : null,
          summary: data['summary'] is Map
              ? PlansSummary.fromJson(
                  (data['summary'] as Map).cast<String, dynamic>(),
                )
              : null,
        );
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /plans
  Future<Plan> createPlan(PlanCreateInput input) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/plans',
        data: input.toJson(),
      );
      if (res.statusCode == 201 && res.data != null) {
        return Plan.fromJson(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// PUT /plans/:id
  Future<Plan> updatePlan(String id, PlanUpdateInput input) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/plans/$id',
        data: input.toJson(),
      );
      if (res.statusCode == 200 && res.data != null) {
        return Plan.fromJson(res.data!);
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

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(ref.watch(dioProvider));
});

/// Paginated list of plans for the active gym. Re-runs when the active
/// gym changes so switching tenants refreshes the data. Pass
/// `includeStats: true` (default in the repository) so the KPI card and
/// per-plan stat columns can render.
final planListProvider = FutureProvider.autoDispose
    .family<PlansResponse, PlanListQuery>((ref, query) {
      ref.watch(activeGymProvider);
      return ref.watch(planRepositoryProvider).getPlans(query);
    });
