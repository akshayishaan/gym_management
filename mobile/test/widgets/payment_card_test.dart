import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/widgets/payment_card.dart';

import '../support/harness.dart';

PaymentListResponsePaymentsInner payment({
  PaymentListResponsePaymentsInnerStatusEnum status =
      PaymentListResponsePaymentsInnerStatusEnum.paid,
  PaymentListResponsePaymentsInnerKindEnum kind =
      PaymentListResponsePaymentsInnerKindEnum.dues,
  String? planName,
  String? membershipId,
  PaymentListResponsePaymentsInnerMembershipStatusEnum? membershipStatus,
}) {
  return PaymentListResponsePaymentsInner(
    id: 'p1',
    gymId: 'g1',
    memberId: 'm1',
    memberName: 'Alice Smith',
    planId: planName != null ? 'plan1' : null,
    planName: planName,
    amount: 1500,
    kind: kind,
    method: PaymentListResponsePaymentsInnerMethodEnum.cash,
    status: status,
    invoiceNumber: 'INV-2601-0001',
    notes: null,
    paidAt: '2026-01-13',
    createdAt: '2026-01-13T00:00:00.000Z',
    updatedAt: '2026-01-13T00:00:00.000Z',
    membershipId: membershipId,
    membershipStatus: membershipStatus,
  );
}

Widget wrapCard(
  PaymentListResponsePaymentsInner payment, {
  VoidCallback? onVoid,
  VoidCallback? onRefund,
  VoidCallback? onReverse,
}) {
  return wrap(
    PaymentCard(
      payment: payment,
      currency: 'INR',
      onInvoice: () {},
      onVoid: onVoid ?? () {},
      onRefund: onRefund ?? () {},
      onReverse: onReverse ?? () {},
    ),
  );
}

void main() {
  testWidgets('renders member name, dues label and method badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapCard(payment()));
    await tester.pumpAndSettle();

    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Dues payment'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.textContaining('INV-2601-0001'), findsOneWidget);
  });

  testWidgets('shows a Voided badge when the payment is voided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapCard(
        payment(
          status: PaymentListResponsePaymentsInnerStatusEnum.voided,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Voided'), findsOneWidget);
  });

  testWidgets('offers reverse for a paid plan purchase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapCard(
        payment(
          kind: PaymentListResponsePaymentsInnerKindEnum.planPurchase,
          planName: 'Monthly',
          membershipId: 'ms1',
          membershipStatus:
              PaymentListResponsePaymentsInnerMembershipStatusEnum.active,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('View invoice'), findsOneWidget);
    expect(find.text('Void payment'), findsOneWidget);
    expect(find.text('Refund payment'), findsOneWidget);
    expect(find.text('Reverse plan purchase'), findsOneWidget);
  });

  testWidgets('hides reverse for a dues payment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapCard(payment()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Reverse plan purchase'), findsNothing);
    expect(find.text('Void payment'), findsOneWidget);
  });

  testWidgets('confirming void dispatches onVoid', (WidgetTester tester) async {
    bool voided = false;
    await tester.pumpWidget(wrapCard(payment(), onVoid: () => voided = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Void payment'));
    await tester.pumpAndSettle();

    expect(find.text('Void this payment?'), findsOneWidget);
    await tester.tap(find.text('Void payment').last);
    await tester.pumpAndSettle();

    expect(voided, isTrue);
  });

  testWidgets('confirming refund dispatches onRefund', (WidgetTester tester) async {
    bool refunded = false;
    await tester.pumpWidget(wrapCard(payment(), onRefund: () => refunded = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refund payment'));
    await tester.pumpAndSettle();

    expect(find.text('Refund this payment?'), findsOneWidget);
    await tester.tap(find.text('Record refund'));
    await tester.pumpAndSettle();

    expect(refunded, isTrue);
  });
}
