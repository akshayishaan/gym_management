import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_repository.dart';
import '../../members/data/member_repository.dart';
import '../../plans/data/plan_repository.dart';
import '../data/payment_repository.dart';
import '../domain/payment.dart';

/// Controller state shared by the record / void / refund notifiers.
class PaymentMutationState {
  const PaymentMutationState({this.loading = false, this.lastError});
  final bool loading;
  final Object? lastError;

  PaymentMutationState copyWith({bool? loading, Object? lastError}) {
    return PaymentMutationState(
      loading: loading ?? this.loading,
      lastError: lastError,
    );
  }
}

/// `POST /payments`. Records a payment through `recordPayment` in
/// `membershipLifecycle.ts`. On success, invalidates the payments list
/// so the new row appears immediately AND the members list (because
/// `recomputeMemberAggregates` adjusts the linked Member's cached
/// `dueAmount`).
class PaymentRecordController
    extends AutoDisposeNotifier<PaymentMutationState> {
  @override
  PaymentMutationState build() => const PaymentMutationState();

  Future<Payment> record(PaymentCreateInput input) async {
    state = const PaymentMutationState(loading: true);
    try {
      final envelope = await ref
          .read(paymentRepositoryProvider)
          .recordPayment(input);
      final paymentJson = envelope['payment'];
      if (paymentJson is! Map) {
        throw StateError(
          'recordPayment: missing payment in lifecycle envelope',
        );
      }
      final payment = Payment.fromJson((paymentJson).cast<String, dynamic>());
      ref.invalidate(paymentListProvider);
      // Cached `dueAmount` on the member changes when a payment (plan
      // purchase or dues) commits, so any visible member list rows need a
      // refresh. Invalidating without an argument clears all family instances.
      ref.invalidate(memberListProvider);
      ref.invalidate(memberDetailProvider(input.memberId));
      // Revenue totals, recent-payments feed, and (for a plan purchase)
      // the expiring-soon list all shift with a new payment.
      ref.invalidate(dashboardProvider);
      // A plan purchase moves that plan's activeMembers/salesYtd/revenue
      // stats shown on the Plans list cards.
      if (input.planId != null) {
        ref.invalidate(planListProvider);
      }
      state = const PaymentMutationState();
      return payment;
    } catch (e) {
      state = PaymentMutationState(lastError: e);
      rethrow;
    }
  }
}

final paymentRecordControllerProvider =
    AutoDisposeNotifierProvider<PaymentRecordController, PaymentMutationState>(
      PaymentRecordController.new,
    );

/// `POST /payments/:id/void`. Voids a paid payment (audit preserved).
/// On success, invalidates the payments list and the detail provider so
/// the row reflects its new `voided` state immediately.
class PaymentVoidController extends AutoDisposeNotifier<PaymentMutationState> {
  @override
  PaymentMutationState build() => const PaymentMutationState();

  Future<void> voidPayment(String id, {String? reason}) async {
    state = const PaymentMutationState(loading: true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .voidPayment(id, PaymentActionInput(reason: reason));
      ref.invalidate(paymentListProvider);
      ref.invalidate(paymentDetailProvider(id));
      // Voids don't touch cached Member aggregates — leave the member
      // list alone to avoid a noisy refresh.
      state = const PaymentMutationState();
    } catch (e) {
      state = PaymentMutationState(lastError: e);
      rethrow;
    }
  }
}

final paymentVoidControllerProvider =
    AutoDisposeNotifierProvider<PaymentVoidController, PaymentMutationState>(
      PaymentVoidController.new,
    );

/// `POST /payments/:id/refund`. Refunds a paid payment (audit preserved,
/// contributes negative cash movement at the refund timestamp). Same
/// invalidation scope as [PaymentVoidController].
class PaymentRefundController
    extends AutoDisposeNotifier<PaymentMutationState> {
  @override
  PaymentMutationState build() => const PaymentMutationState();

  Future<void> refund(String id, {String? reason}) async {
    state = const PaymentMutationState(loading: true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .refundPayment(id, PaymentActionInput(reason: reason));
      ref.invalidate(paymentListProvider);
      ref.invalidate(paymentDetailProvider(id));
      state = const PaymentMutationState();
    } catch (e) {
      state = PaymentMutationState(lastError: e);
      rethrow;
    }
  }
}

final paymentRefundControllerProvider =
    AutoDisposeNotifierProvider<PaymentRefundController, PaymentMutationState>(
      PaymentRefundController.new,
    );
