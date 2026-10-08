import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/dio_client.dart';
import 'package:gym_manager/features/members/presentation/member_form_sheet.dart';
import 'package:gym_manager/features/plans/data/plan_repository.dart';
import 'package:gym_manager/features/plans/domain/plan.dart';
import 'package:gym_manager/features/plans/domain/plans_response.dart';

class _Backend implements HttpClientAdapter {
  final posts = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST' && options.path == '/members') {
      posts.add((options.data as Map).cast<String, dynamic>());
      return ResponseBody.fromString(
        jsonEncode({
          'member': {'_id': 'm9', 'gymId': 'g1', 'name': 'Test', 'phone': '1'},
          'payment': null,
        }),
        201,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

const _plans = PlansResponse(
  plans: [
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
      name: 'Quarterly',
      durationDays: 90,
      price: 2500,
      features: [],
    ),
  ],
  total: 2,
  page: 1,
  limit: 100,
  counts: PlanCounts(all: 2, active: 2, inactive: 0),
);

Future<_Backend> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = _Backend();
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = backend;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        dioProvider.overrideWithValue(dio),
        planListProvider.overrideWith((ref, query) async => _plans),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: MemberFormSheet()),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return backend;
}

Future<void> _choosePlan(WidgetTester tester, String name) async {
  await tester.tap(find.text('No plan'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Finder get _amountField => find.byType(TextFormField).at(5);

void main() {
  testWidgets('no payment section until a plan is chosen', (tester) async {
    await _open(tester);
    expect(find.text('PAYMENT'), findsNothing);
    expect(find.text('Amount paid now'), findsNothing);
  });

  testWidgets('choosing a plan offers the full price as paid', (tester) async {
    await _open(tester);
    await _choosePlan(tester, 'Monthly');

    expect(find.text('PAYMENT'), findsOneWidget);
    expect(find.text('Plan price'), findsOneWidget);
    expect(find.text('₹1,000'), findsOneWidget);
    expect(find.text('Start date'), findsOneWidget);
    expect(tester.widget<TextFormField>(_amountField).controller!.text, '1000');
    expect(find.text('Paid in full'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
  });

  testWidgets('partial payment shows the remaining due live', (tester) async {
    await _open(tester);
    await _choosePlan(tester, 'Monthly');

    await tester.enterText(_amountField, '400');
    await tester.pump();
    expect(find.text('Due after this payment: ₹600'), findsOneWidget);
    expect(find.text('Paid in full'), findsNothing);

    await tester.enterText(_amountField, '0');
    await tester.pump();
    expect(
      find.text('No payment recorded. ₹1,000 will be due.'),
      findsOneWidget,
    );
    // Nothing paid: no method to choose.
    expect(find.text('Payment Method'), findsNothing);
  });

  testWidgets('amount above the plan price is rejected', (tester) async {
    final backend = await _open(tester);
    await _choosePlan(tester, 'Monthly');

    await tester.enterText(find.byType(TextFormField).at(0), 'Test Member');
    await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
    await tester.enterText(_amountField, '1500');
    await tester.tap(find.text('ADD MEMBER'));
    await tester.pumpAndSettle();

    expect(find.text('Cannot exceed the plan price (₹1,000)'), findsOneWidget);
    expect(backend.posts, isEmpty);
  });

  testWidgets('non-cash method asks for a reference', (tester) async {
    await _open(tester);
    await _choosePlan(tester, 'Monthly');

    expect(find.text('Reference / Transaction ID'), findsNothing);
    await tester.tap(find.text('UPI'));
    await tester.pump();
    expect(find.text('Reference / Transaction ID'), findsOneWidget);
    await tester.tap(find.text('Cash'));
    await tester.pump();
    expect(find.text('Reference / Transaction ID'), findsNothing);
  });

  testWidgets('switching plan resets the amount; No plan removes the section', (
    tester,
  ) async {
    await _open(tester);
    await _choosePlan(tester, 'Monthly');
    await tester.enterText(_amountField, '400');
    await tester.pump();

    await tester.tap(find.text('Monthly').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quarterly'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(_amountField).controller!.text, '2500');

    await tester.tap(find.text('Quarterly').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('No plan').last);
    await tester.pumpAndSettle();
    expect(find.text('PAYMENT'), findsNothing);
  });

  testWidgets('submits plan, amount, method, reference and start date', (
    tester,
  ) async {
    final backend = await _open(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Member');
    await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
    await _choosePlan(tester, 'Monthly');

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(_amountField, '400');
    await tester.pump();
    await tester.tap(find.text('UPI'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(6), 'TXN123');
    await tester.tap(find.text('ADD MEMBER'));
    await tester.pumpAndSettle();

    expect(backend.posts, hasLength(1));
    final body = backend.posts.single;
    expect(body['planId'], 'p1');
    expect(body['amountPaid'], 400);
    expect(body['paymentMethod'], 'upi');
    expect(body['reference'], 'TXN123');
    expect(body['membershipStart'], matches(r'^\d{4}-\d{2}-\d{2}$'));
  });

  testWidgets('zero paid sends no method or reference', (tester) async {
    final backend = await _open(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Member');
    await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
    await _choosePlan(tester, 'Monthly');

    await tester.enterText(_amountField, '0');
    await tester.tap(find.text('ADD MEMBER'));
    await tester.pumpAndSettle();

    final body = backend.posts.single;
    expect(body['planId'], 'p1');
    expect(body['amountPaid'], 0);
    expect(body.containsKey('paymentMethod'), isFalse);
    expect(body.containsKey('reference'), isFalse);
    expect(body.containsKey('membershipStart'), isFalse);
  });
}
