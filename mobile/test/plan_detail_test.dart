import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/plans/data/plan_repository.dart';
import 'package:gym_manager/features/plans/domain/plan.dart';
import 'package:gym_manager/features/plans/domain/plans_response.dart';
import 'package:gym_manager/features/plans/presentation/plan_detail_screen.dart';

Plan _plan({bool active = true}) => Plan(
  id: 'p1',
  gymId: 'g1',
  name: 'Monthly',
  durationDays: 30,
  price: 150000,
  features: const ['24/7 Access'],
  isActive: active,
  createdAt: DateTime.utc(2026, 7, 27, 10),
  updatedAt: DateTime.utc(2026, 7, 28, 10),
  stats: const PlanStats(
    activeMembers: 2,
    salesYtd: 6,
    revenueAtSaleYtd: 500000,
  ),
);

Future<void> _open(WidgetTester tester, List<Plan> plans) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        planListProvider.overrideWith(
          (ref, query) async => PlansResponse(
            plans: plans,
            total: plans.length,
            page: 1,
            limit: 100,
          ),
        ),
      ],
      child: const MaterialApp(home: PlanDetailScreen(id: 'p1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('active plan: rupees, day-first dates, one edit entry', (
    tester,
  ) async {
    await _open(tester, [_plan()]);

    expect(find.textContaining('\$'), findsNothing);
    expect(find.text('₹5,00,000'), findsOneWidget);
    expect(find.text('Active members'), findsOneWidget);
    expect(find.text('Created 27 Jul 2026'), findsOneWidget);
    expect(find.text('Updated 28 Jul 2026'), findsOneWidget);
    expect(find.text('Edit Plan'), findsNothing);
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.text('Deactivate'), findsOneWidget);
    expect(find.text('Reactivate'), findsNothing);
  });

  testWidgets('paused plan can be reactivated', (tester) async {
    await _open(tester, [_plan(active: false)]);

    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('Reactivate'), findsOneWidget);
    expect(find.text('Deactivate'), findsNothing);
  });

  testWidgets('missing plan shows a plain message', (tester) async {
    await _open(tester, const []);

    expect(find.text('Plan not found'), findsOneWidget);
    expect(find.text('Back to plans'), findsOneWidget);
    expect(find.textContaining('first page'), findsNothing);
  });
}
