import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/payments/data/payment_repository.dart';
import 'package:gym_manager/features/payments/domain/payment.dart';
import 'package:gym_manager/features/payments/domain/payment_query.dart';
import 'package:gym_manager/features/payments/presentation/payments_screen.dart';

Payment _payment(
  int i, {
  String status = 'paid',
  double amount = 1000,
  String paidAt = '2026-10-06T08:38:00.000Z',
}) {
  return Payment.fromJson({
    '_id': 'p$i',
    'gymId': 'g1',
    'memberId': 'm$i',
    'memberName': 'Member $i',
    'planName': 'Monthly',
    'amount': amount,
    'method': 'cash',
    'status': status,
    'invoiceNumber': 'INV-$i',
    'paidAt': paidAt,
  });
}

/// Serves [all] in pages of [pageSize], honouring `query.status` the way the
/// backend does, and records every query the screen makes.
class _Fake {
  _Fake(this.all, {this.pageSize = 50});
  final List<Payment> all;
  final int pageSize;
  final queries = <PaymentListQuery>[];

  Future<PaymentsListResult> call(PaymentListQuery q) async {
    queries.add(q);
    final matching = [
      for (final p in all)
        if (q.status == null || p.status == q.status) p,
    ];
    final start = (q.page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, matching.length);
    return PaymentsListResult(
      payments: start >= matching.length
          ? const []
          : matching.sublist(start, end),
      total: matching.length,
      page: q.page,
      limit: pageSize,
      netAmount: 150000,
    );
  }
}

Widget _host(_Fake fake) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [paymentListProvider.overrideWith((ref, query) => fake(query))],
    child: const MaterialApp(home: PaymentsScreen()),
  );
}

void main() {
  testWidgets('shows rupees with Indian grouping and day-first dates', (
    tester,
  ) async {
    final fake = _Fake([_payment(1, amount: 125000)]);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    expect(find.text('₹1,50,000'), findsOneWidget); // KPI whole part
    expect(find.text('+₹1,25,000.00'), findsOneWidget);
    expect(find.textContaining('\$'), findsNothing);
    expect(find.textContaining('6 Oct 2026'), findsOneWidget);
  });

  testWidgets('voided and refunded cards are labelled and have no actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = _Fake([
      _payment(1),
      _payment(2, status: 'voided'),
      _payment(3, status: 'refunded'),
    ]);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    expect(find.text('VOIDED'), findsOneWidget);
    expect(find.text('REFUNDED'), findsOneWidget);
    // Only the paid card offers Void / Refund / receipt.
    expect(find.text('Void'), findsOneWidget);
    expect(find.text('Refund'), findsOneWidget);
    expect(find.byTooltip('View receipt'), findsOneWidget);
  });

  testWidgets('the Pending pill is gone; Voided filters on the server', (
    tester,
  ) async {
    final fake = _Fake([_payment(1), _payment(2, status: 'voided')]);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsNothing);
    expect(find.text('All (2)'), findsOneWidget);

    await tester.tap(find.text('Voided'));
    await tester.pumpAndSettle();

    expect(fake.queries.last.status, 'voided');
    expect(find.text('Voided (1)'), findsOneWidget);
    expect(find.text('1 voided payment • All time'), findsOneWidget);
  });

  testWidgets('empty states tell a filter miss from an empty ledger', (
    tester,
  ) async {
    final fake = _Fake([_payment(1)]);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Refunded'));
    await tester.pumpAndSettle();
    expect(find.text('No payments match'), findsOneWidget);
    expect(find.text('No payments yet'), findsNothing);

    final empty = _Fake([]);
    await tester.pumpWidget(_host(empty));
    await tester.pumpAndSettle();
    expect(find.text('No payments yet'), findsOneWidget);
  });

  testWidgets('Load more appends the next page', (tester) async {
    final fake = _Fake([for (var i = 1; i <= 7; i++) _payment(i)], pageSize: 3);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    final more = find.text('Load more');
    await tester.scrollUntilVisible(
      more,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Showing 3 of 7'), findsOneWidget);

    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(fake.queries.map((q) => q.page), containsAll([1, 2]));
    expect(find.text('Member 4'), findsOneWidget);
  });

  testWidgets('month sheet offers All time and recent months', (tester) async {
    final fake = _Fake([_payment(1)]);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All time').first);
    await tester.pumpAndSettle();
    expect(find.text('Select Month'), findsOneWidget);

    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final current = '${months[now.month - 1]} ${now.year}';
    await tester.tap(find.text(current));
    await tester.pumpAndSettle();

    expect(find.text('Select Month'), findsNothing);
    expect(fake.queries.last.month, matches(RegExp(r'^\d{4}-\d{2}$')));
  });
}
