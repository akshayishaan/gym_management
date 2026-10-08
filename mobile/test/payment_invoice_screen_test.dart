import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/payments/data/payment_repository.dart';
import 'package:gym_manager/features/payments/domain/payment.dart';
import 'package:gym_manager/features/payments/presentation/payment_invoice_screen.dart';

Payment _payment({String status = 'paid', double amount = 150000}) => Payment(
  id: 'p1',
  gymId: 'g1',
  memberId: 'm1',
  memberName: 'Sumit Raj',
  kind: 'plan_purchase',
  planName: 'Monthly',
  planDurationDays: 30,
  amount: amount,
  method: 'cash',
  status: status,
  invoiceNumber: 'INV-2610-0013',
  paidAt: DateTime.utc(2026, 10, 6, 2, 8),
  voidedAt: DateTime.utc(2026, 10, 7),
);

Future<void> _open(WidgetTester tester, Payment payment) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        paymentDetailProvider('p1').overrideWith((ref) async => payment),
      ],
      child: const MaterialApp(home: PaymentInvoiceScreen(id: 'p1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('paid receipt: rupees, real rows only, actions available', (
    tester,
  ) async {
    await _open(tester, _payment());

    expect(find.text('₹1,50,000'), findsOneWidget);
    expect(find.textContaining('\$'), findsNothing);
    expect(find.textContaining('USD'), findsNothing);
    expect(find.text('PAID'), findsOneWidget);
    expect(find.text('SETTLED'), findsNothing);
    expect(find.textContaining('Tax'), findsNothing);
    expect(find.textContaining('Processing'), findsNothing);
    expect(find.text('BILLING PERIOD'), findsNothing);
    expect(find.text('Plan purchase'), findsOneWidget);
    expect(find.textContaining('Settled on 6 Oct 2026'), findsOneWidget);
    expect(find.text('Void'), findsOneWidget);
    expect(find.text('Refund'), findsOneWidget);
    expect(find.text('Share Receipt'), findsOneWidget);
    expect(find.text('Print Receipt'), findsOneWidget);
  });

  testWidgets('voided receipt: muted amount, status chip, no actions', (
    tester,
  ) async {
    await _open(tester, _payment(status: 'voided'));

    expect(find.text('VOIDED'), findsOneWidget);
    expect(find.text('AMOUNT (VOIDED)'), findsOneWidget);
    expect(find.text('Void'), findsNothing);
    expect(find.text('Refund'), findsNothing);
    expect(find.text('Share Receipt'), findsNothing);
    expect(find.text('Voided on 7 Oct 2026'), findsOneWidget);
    final amount = tester.widget<Text>(find.text('₹1,50,000'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
  });
}
