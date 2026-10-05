import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/dio_client.dart';
import '../../gym/application/active_gym_controller.dart';
import '../domain/payment.dart';
import '../domain/payment_query.dart';

/// Plain Dart transport shape for `POST /payments`. Server validates with
/// `paymentCreateSchema` in `backend/src/payments/payment.schemas.ts`.
/// `requestId` is auto-generated as a UUID v4 so the backend's
/// `runIdempotent` wrapper in `membershipLifecycle.ts` can dedupe
/// retries without the caller managing it.
class PaymentCreateInput {
  PaymentCreateInput({
    required this.memberId,
    required this.amount,
    required this.method,
    this.planId,
    this.membershipStart,
    this.notes,
    String? requestId,
  }) : requestId = requestId ?? const Uuid().v4();

  /// Client-generated UUID v4. The backend uses this to make the
  /// lifecycle mutation idempotent. Re-generated per call by default so
  /// the backend doesn't dedupe retries the user didn't make.
  final String requestId;
  final String memberId;
  final String? planId;
  final double amount;
  final String method; // 'cash' | 'card' | 'upi' | 'bank_transfer' | 'other'
  final String? membershipStart; // YYYY-MM-DD
  final String? notes;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'memberId': memberId,
        if (planId != null && planId!.isNotEmpty) 'planId': planId,
        'amount': amount,
        'method': method,
        if (membershipStart != null && membershipStart!.isNotEmpty)
          'membershipStart': membershipStart,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

/// Plain Dart transport shape for `POST /payments/:id/void` and
/// `POST /payments/:id/refund`. Validated by `paymentActionSchema`.
class PaymentActionInput {
  PaymentActionInput({this.reason, String? requestId})
      : requestId = requestId ?? const Uuid().v4();

  /// Client-generated UUID v4. Auto-generated per call; a fresh id keeps
  /// each action isolated from any prior retry the caller didn't make.
  final String requestId;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };
}

/// Network access for the Payments feature. Routes live in
/// `backend/src/payments/payment.controller.ts` and are scoped to the
/// selected gym via `RequireGymGuard` (the `X-Selected-Gym` header is
/// attached by `dio_client.dart`).
class PaymentRepository {
  PaymentRepository(this._dio);
  final Dio _dio;

  /// GET /payments?month=&page=&limit=
  Future<PaymentsListResult> getPayments(PaymentListQuery query) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/payments',
        queryParameters: {
          if (query.month != null && query.month!.isNotEmpty)
            'month': query.month,
          'page': query.page,
          'limit': query.limit,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data!;
        final list = (data['payments'] as List?) ?? const [];
        final summary = (data['summary'] is Map)
            ? (data['summary'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
        return PaymentsListResult(
          payments: list
              .whereType<Map<String, dynamic>>()
              .map(Payment.fromJson)
              .toList(),
          total: (data['total'] as num?)?.toInt() ?? list.length,
          page: (data['page'] as num?)?.toInt() ?? query.page,
          limit: (data['limit'] as num?)?.toInt() ?? query.limit,
          netAmount: (summary['netAmount'] as num?)?.toDouble() ?? 0,
        );
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// GET /payments/:id — returns the raw Payment document (no list-side
  /// membership enrichment).
  Future<Payment> getPayment(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/payments/$id');
      if (res.statusCode == 200 && res.data != null) {
        return Payment.fromJson(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /payments — records a payment via `recordPayment` in
  /// `membershipLifecycle.ts`. Returns the raw lifecycle envelope
  /// (typically `{ payment, membership }`; `membership` is null for a
  /// pure dues payment).
  Future<Map<String, dynamic>> recordPayment(PaymentCreateInput input) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/payments',
        data: input.toJson(),
      );
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null) {
        return res.data!;
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /payments/:id/void — voids a paid payment (preserves audit).
  /// Returns the raw lifecycle envelope from `voidPayment`.
  Future<Map<String, dynamic>> voidPayment(
    String id,
    PaymentActionInput input,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/payments/$id/void',
        data: input.toJson(),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data!;
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /payments/:id/refund — refunds a paid payment (preserves
  /// audit; contributes negative cash movement at the refund timestamp).
  /// Returns the raw lifecycle envelope from `refundPayment`.
  Future<Map<String, dynamic>> refundPayment(
    String id,
    PaymentActionInput input,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/payments/$id/refund',
        data: input.toJson(),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data!;
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

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});

/// Paginated list of payments for the active gym. Re-runs when the
/// active gym changes so switching tenants refreshes the ledger.
final paymentListProvider =
    FutureProvider.autoDispose.family<PaymentsListResult, PaymentListQuery>(
  (ref, query) {
    ref.watch(activeGymProvider);
    return ref.watch(paymentRepositoryProvider).getPayments(query);
  },
);

/// Single-payment detail. Watches the active gym so tenant switches
/// invalidate the open detail page.
final paymentDetailProvider =
    FutureProvider.autoDispose.family<Payment, String>((ref, id) {
  ref.watch(activeGymProvider);
  return ref.watch(paymentRepositoryProvider).getPayment(id);
});