import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/members/data/member_repository.dart';
import 'package:gym_manager/features/members/domain/member.dart';
import 'package:gym_manager/features/payments/presentation/payment_form_sheet.dart';
import 'package:gym_manager/features/plans/data/plan_repository.dart';
import 'package:gym_manager/features/plans/domain/plan.dart';
import 'package:gym_manager/features/plans/domain/plans_response.dart';

Member _member({double due = 0}) => Member(
  id: 'm1',
  gymId: 'g1',
  name: 'Akshay Kumar',
  phone: '8866325411',
  dueAmount: due,
);

Future<void> _open(
  WidgetTester tester, {
  Member? member,
  List<Member>? all,
  bool withPlans = false,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        // The sheet prefetches plans when it opens, so always stub them
        // (empty unless [withPlans]) to keep the real network out of tests.
        // Behaves like the server: status 'active' hides paused plans.
        planListProvider.overrideWith((ref, query) async {
          const plans = [
            Plan(
              id: 'p1',
              gymId: 'g1',
              name: 'Monthly',
              durationDays: 30,
              price: 1000,
              features: [],
            ),
            Plan(
              id: 'p2',
              gymId: 'g1',
              name: 'Paused Plan',
              durationDays: 30,
              price: 800,
              features: [],
              isActive: false,
            ),
          ];
          if (!withPlans) {
            return PlansResponse(
              plans: const [],
              total: 0,
              page: 1,
              limit: 100,
              counts: const PlanCounts(all: 0, active: 0, inactive: 0),
            );
          }
          final shown = query.status == 'active'
              ? plans.where((p) => p.isActive).toList()
              : plans;
          return PlansResponse(
            plans: shown,
            total: shown.length,
            page: 1,
            limit: 100,
            counts: const PlanCounts(all: 2, active: 1, inactive: 1),
          );
        }),
        if (all != null)
          memberListProvider.overrideWith(
            (ref, query) async => MemberListResult(
              members: all
                  .where(
                    (m) =>
                        query.search == null ||
                        m.name.toLowerCase().contains(
                          query.search!.toLowerCase(),
                        ),
                  )
                  .toList(),
              total: all.length,
              page: 1,
              limit: query.limit,
            ),
          ),
      ],
      child: MaterialApp(
        home: Scaffold(body: PaymentFormSheet(member: member)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dues are offered as the amount, in rupees', (tester) async {
    await _open(tester, member: _member(due: 500));

    expect(find.text('Amount (₹)'), findsOneWidget);
    expect(find.textContaining('\$'), findsNothing);
    expect(find.text('Outstanding: ₹500'), findsOneWidget);
    expect(find.text('500.00'), findsOneWidget);
    expect(find.text('Dues payment (no plan)'), findsOneWidget);
  });

  testWidgets('amount above the outstanding balance is rejected', (
    tester,
  ) async {
    await _open(tester, member: _member(due: 500));

    await tester.enterText(find.byType(TextFormField).first, '600');
    await tester.tap(find.text('RECORD PAYMENT'));
    await tester.pumpAndSettle();

    expect(find.text('Cannot exceed the outstanding ₹500'), findsOneWidget);
  });

  testWidgets('no dues and no plan: explains and disables the button', (
    tester,
  ) async {
    await _open(tester, member: _member());

    expect(
      find.text('No dues to settle. Pick a plan to record a purchase.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('reference only appears for non-cash methods', (tester) async {
    await _open(tester, member: _member(due: 500));

    expect(find.text('Reference / Transaction ID'), findsNothing);
    await tester.tap(find.text('UPI'));
    await tester.pumpAndSettle();
    expect(find.text('Reference / Transaction ID'), findsOneWidget);
    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    expect(find.text('Reference / Transaction ID'), findsNothing);
  });

  testWidgets('empty member field shows its hint and the picker searches', (
    tester,
  ) async {
    await _open(
      tester,
      all: [
        _member(due: 500),
        const Member(id: 'm2', gymId: 'g1', name: 'Sumit Raj', phone: '1'),
      ],
    );

    expect(find.text('Select member'), findsOneWidget);
    await tester.tap(find.text('Select member'));
    await tester.pumpAndSettle();
    expect(find.text('Akshay Kumar'), findsOneWidget);
    expect(find.text('Sumit Raj'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'sumit');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Akshay Kumar'), findsNothing);
    expect(find.text('Sumit Raj'), findsOneWidget);

    await tester.tap(find.text('Sumit Raj'));
    await tester.pumpAndSettle();
    expect(find.text('Sumit Raj'), findsOneWidget);
    expect(find.text('Dues payment (no plan)'), findsOneWidget);
  });

  testWidgets('fixed member shows the card, with no way to change it', (
    tester,
  ) async {
    await _open(tester, member: _member(due: 500));

    expect(find.text('Akshay Kumar'), findsOneWidget);
    expect(find.text('8866325411'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget);
    // Member is not an input here: only Amount and Method are required.
    expect(find.text('*'), findsNWidgets(2));
    // Only the Plan field has a chevron.
    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    await tester.tap(find.text('Akshay Kumar'));
    await tester.pumpAndSettle();
    expect(find.text('Select Member'), findsNothing);
  });

  testWidgets('picked member shows the same card and can be changed', (
    tester,
  ) async {
    await _open(
      tester,
      all: [
        _member(due: 500),
        const Member(
          id: 'm2',
          gymId: 'g1',
          name: 'Sumit Raj',
          phone: '9000000002',
        ),
      ],
    );

    await tester.tap(find.text('Select member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akshay Kumar'));
    await tester.pumpAndSettle();

    // Same card as a fixed member: name, phone, due.
    expect(find.text('Akshay Kumar'), findsOneWidget);
    expect(find.text('8866325411'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('Select member'), findsNothing);
    // Here Member is an input: required marker + a chevron on the card.
    expect(find.text('*'), findsNWidgets(3));
    expect(find.byIcon(Icons.expand_more), findsNWidgets(2));

    // Tapping the card reopens the picker; choosing someone else swaps it.
    await tester.tap(find.text('Akshay Kumar'));
    await tester.pumpAndSettle();
    expect(find.text('Select Member'), findsOneWidget);
    await tester.tap(find.text('Sumit Raj'));
    await tester.pumpAndSettle();

    expect(find.text('Sumit Raj'), findsOneWidget);
    expect(find.text('Akshay Kumar'), findsNothing);
    expect(find.text('Due'), findsNothing);
    expect(find.text('Dues payment (no plan)'), findsOneWidget);
  });

  group('balance after this payment', () {
    testWidgets('dues payment: cleared, partial, and over-the-limit', (
      tester,
    ) async {
      await _open(tester, member: _member(due: 500));
      final amount = find.byType(TextFormField).first;

      // Prefilled with the full outstanding balance.
      expect(find.text('All dues cleared'), findsOneWidget);

      await tester.enterText(amount, '200');
      await tester.pump();
      expect(find.text('Due after this payment: ₹300'), findsOneWidget);
      expect(find.text('All dues cleared'), findsNothing);

      await tester.enterText(amount, '600');
      await tester.pump();
      expect(find.textContaining('Due after this payment'), findsNothing);
      expect(find.text('All dues cleared'), findsNothing);

      await tester.enterText(amount, '');
      await tester.pump();
      expect(find.textContaining('Due after this payment'), findsNothing);
    });

    testWidgets('plan purchase for a member with no dues', (tester) async {
      await _open(tester, member: _member(), withPlans: true);

      await tester.tap(find.text('Dues payment (no plan)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      // Amount defaults to the plan price.
      expect(find.text('Paid in full'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '400');
      await tester.pump();
      expect(find.text('Due after this payment: ₹600'), findsOneWidget);
      expect(find.textContaining('earlier dues'), findsNothing);

      await tester.enterText(find.byType(TextFormField).first, '1500');
      await tester.pump();
      expect(find.textContaining('Due after this payment'), findsNothing);
      expect(find.text('Paid in full'), findsNothing);
    });

    testWidgets('plan purchase carries earlier dues into the balance', (
      tester,
    ) async {
      await _open(tester, member: _member(due: 500), withPlans: true);

      await tester.tap(find.text('Dues payment (no plan)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      // Pays the whole plan; the earlier ₹500 is still owed.
      expect(find.text('Due after this payment: ₹500'), findsOneWidget);
      expect(find.text('Includes ₹500 from earlier dues.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '400');
      await tester.pump();
      expect(find.text('Due after this payment: ₹1,100'), findsOneWidget);
    });

    testWidgets('no balance line before a member is chosen', (tester) async {
      await _open(tester, all: [_member(due: 500)]);
      expect(find.textContaining('Due after this payment'), findsNothing);
      expect(find.text('All dues cleared'), findsNothing);
    });
  });

  testWidgets('plan picker lists active plans only', (tester) async {
    await _open(tester, member: _member(due: 500), withPlans: true);

    await tester.tap(find.text('Dues payment (no plan)'));
    await tester.pumpAndSettle();
    expect(find.text('Select Plan'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Paused Plan'), findsNothing);
  });
}
