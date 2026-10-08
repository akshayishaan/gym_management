import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/plans/data/plan_repository.dart';
import 'package:gym_manager/features/plans/domain/plan.dart';
import 'package:gym_manager/features/plans/domain/plans_response.dart';
import 'package:gym_manager/features/plans/presentation/plans_list_screen.dart';

const _plan = Plan(
  id: 'p1',
  gymId: 'g1',
  name: 'Monthly',
  durationDays: 30,
  price: 150000,
  features: ['24/7 Access', 'Recovery Lab'],
  stats: PlanStats(activeMembers: 2, salesYtd: 6, revenueAtSaleYtd: 500000),
);

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        planListProvider.overrideWith(
          (ref, query) async => const PlansResponse(
            plans: [_plan],
            total: 3,
            page: 1,
            limit: 50,
            // 2 active plans, 1 paused; only one plan has active members.
            counts: PlanCounts(all: 3, active: 2, inactive: 1),
            summary: PlansSummary(
              activePlans: 1,
              activeMembers: 2,
              salesYtd: 6,
              revenueAtSaleYtd: 500000,
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: PlansListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  _filterReloadTest();
  testWidgets('amounts are rupees with Indian grouping', (tester) async {
    await _open(tester);

    expect(find.textContaining('\$'), findsNothing);
    expect(find.text('₹5,00,000'), findsNWidgets(2)); // KPI + YTD revenue cell
    expect(
      find.textContaining('₹1,50,000', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('pill counts come from the gym-wide counts', (tester) async {
    await _open(tester);

    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Active (2)'), findsOneWidget);
    expect(find.text('Paused (1)'), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsNothing);
    expect(find.text('Search plans'), findsOneWidget);
  });

  testWidgets('Duplicate opens New Plan pre-filled as a copy', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly (Copy)'), findsOneWidget);
    expect(find.textContaining('coming soon'), findsNothing);
  });
}

void _filterReloadTest() {
  testWidgets('changing the filter keeps the page and shows skeleton cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pending = Completer<PlansResponse>();
    const all = PlansResponse(
      plans: [_plan],
      total: 3,
      page: 1,
      limit: 50,
      counts: PlanCounts(all: 3, active: 2, inactive: 1),
    );
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          planListProvider.overrideWith(
            (ref, query) =>
                query.status == 'active' ? pending.future : Future.value(all),
          ),
        ],
        child: const MaterialApp(home: PlansListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Active (2)'));
    await tester.pump();

    // New query is loading: page, search field and pills are still there.
    expect(find.text('Search plans'), findsOneWidget);
    expect(find.text('Paused (1)'), findsOneWidget);
    expect(find.byKey(const Key('plans-skeleton')), findsOneWidget);
    expect(find.text('Monthly'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    pending.complete(all);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plans-skeleton')), findsNothing);
    expect(find.text('Monthly'), findsOneWidget);
  });
}
