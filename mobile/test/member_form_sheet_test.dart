import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/members/domain/member.dart';
import 'package:gym_manager/features/members/presentation/member_form_sheet.dart';
import 'package:gym_manager/features/plans/data/plan_repository.dart';
import 'package:gym_manager/features/plans/domain/plan.dart';
import 'package:gym_manager/features/plans/domain/plans_response.dart';

Future<void> _open(WidgetTester tester, {Member? member}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        planListProvider.overrideWith(
          (ref, query) async => PlansResponse(
            plans: const [
              Plan(
                id: 'p1',
                gymId: 'g1',
                name: 'Monthly',
                durationDays: 30,
                price: 1000,
                features: [],
              ),
            ],
            total: 1,
            page: 1,
            limit: 100,
            counts: const PlanCounts(all: 1, active: 1, inactive: 0),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: MemberFormSheet(existingMember: member)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pickers show hints and placeholders are neutral', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Select'), findsNWidgets(2)); // date of birth, gender
    expect(find.text('No plan'), findsOneWidget);
    expect(find.text('e.g., Rahul Sharma'), findsOneWidget);
    expect(find.text('98765 43210'), findsOneWidget);
    expect(find.textContaining('Jane'), findsNothing);
    expect(find.textContaining('+1 555'), findsNothing);
  });

  testWidgets('phone needs at least 10 digits', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Rahul');
    await tester.enterText(find.byType(TextFormField).at(1), '12345');
    await tester.tap(find.text('ADD MEMBER'));
    await tester.pump();
    expect(find.text('Enter a valid phone number'), findsOneWidget);
  });

  testWidgets('plan picker lists price and duration and can be chosen', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('No plan'));
    await tester.pumpAndSettle();
    expect(find.text('Select Plan'), findsOneWidget);
    expect(find.textContaining('₹1,000', findRichText: true), findsOneWidget);
    expect(find.textContaining('30 days'), findsOneWidget);

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly'), findsOneWidget);
  });

  testWidgets('edit mode shows capitalised gender and a read-only plan', (
    tester,
  ) async {
    await _open(
      tester,
      member: const Member(
        id: 'm1',
        gymId: 'g1',
        name: 'Akshay',
        phone: '8866325411',
        gender: 'male',
        dateOfBirth: '1998-07-14',
        planId: 'p1',
        planName: 'Monthly',
      ),
    );

    expect(find.text('Male'), findsOneWidget);
    expect(find.text('14 Jul 1998'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(
      find.text('To change the plan, use Record Payment.'),
      findsOneWidget,
    );
    // Read-only plan field: tapping it opens nothing.
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.text('Select Plan'), findsNothing);
  });

  testWidgets('plan picker opens at once while plans are still loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pending = Completer<PlansResponse>();
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          planListProvider.overrideWith((ref, query) => pending.future),
        ],
        child: const MaterialApp(home: Scaffold(body: MemberFormSheet())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('No plan'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Select Plan'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(
      const PlansResponse(
        plans: [
          Plan(
            id: 'p1',
            gymId: 'g1',
            name: 'Monthly',
            durationDays: 30,
            price: 1000,
            features: [],
          ),
        ],
        total: 1,
        page: 1,
        limit: 100,
        counts: PlanCounts(all: 1, active: 1, inactive: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Monthly'), findsOneWidget);
  });
}
