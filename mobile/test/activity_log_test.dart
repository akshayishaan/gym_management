import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/activity/data/activity_repository.dart';
import 'package:gym_manager/features/activity/domain/activity_log.dart';
import 'package:gym_manager/features/activity/domain/activity_log_query.dart';
import 'package:gym_manager/features/activity/presentation/activity_log_screen.dart';

ActivityLog _log(
  String id, {
  String action = 'created',
  String entity = 'member',
  String details = 'Created member Asha.',
  String day = '2026-10-08',
  String time = '10:55',
  String staff = 'Akshay Kumar',
}) => ActivityLog(
  id: id,
  staffName: staff,
  action: action,
  entity: entity,
  entityId: '6ac729553ad5eae6f6540754',
  details: details,
  createdAt: DateTime.parse('${day}T$time:00Z'),
  day: day,
  time: time,
);

/// A fake server: records each query and answers like the real one for the
/// filters the screen can send.
class _Server {
  final queries = <ActivityLogQuery>[];

  ActivityLogPage answer(ActivityLogQuery q) {
    queries.add(q);
    final all = [
      _log('1'),
      _log('2', action: 'voided', entity: 'payment', details: 'Voided INV-1.'),
      _log(
        '3',
        day: '2026-10-07',
        time: '09:10',
        action: 'updated',
        entity: 'plan',
        details: 'Updated plan: Monthly',
      ),
    ];
    var rows = all;
    if (q.range == 'today') {
      rows = rows.where((l) => l.day == '2026-10-08').toList();
    }
    if (q.from != null) {
      rows = rows
          .where(
            (l) =>
                l.day!.compareTo(q.from!) >= 0 && l.day!.compareTo(q.to!) <= 0,
          )
          .toList();
    }
    if (q.actions != null && q.actions!.isNotEmpty) {
      rows = rows.where((l) => q.actions!.contains(l.action)).toList();
    }
    return ActivityLogPage(
      logs: rows,
      total: rows.length,
      page: 1,
      limit: q.limit,
      today: '2026-10-08',
    );
  }
}

Future<_Server> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final server = _Server();
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        activityLogProvider.overrideWith((ref, q) async => server.answer(q)),
      ],
      child: const MaterialApp(home: ActivityLogScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return server;
}

void main() {
  testWidgets('Today asks the server and uses the gym date, not the device', (
    tester,
  ) async {
    final server = await _open(tester);

    expect(server.queries.first.range, 'today');
    expect(find.text('ACTIVITY'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('events today'), findsOneWidget);
    // The gym's today is 8 Oct 2026 whatever this machine's clock says.
    expect(find.text('Today, 8 Oct 2026'), findsOneWidget);
    expect(find.text('Showing 2 of 2 events'), findsOneWidget);
    expect(find.text('Load More Events'), findsNothing);
    expect(find.byIcon(Icons.tune), findsNothing);
    expect(find.textContaining('coming soon'), findsNothing);
  });

  testWidgets('Past 7 Days: count and caption follow the range', (
    tester,
  ) async {
    final server = await _open(tester);
    await tester.tap(find.text('Past 7 Days'));
    await tester.pumpAndSettle();

    expect(server.queries.last.range, 'week');
    expect(find.text('3'), findsOneWidget);
    expect(find.text('events in the last 7 days'), findsOneWidget);
    expect(find.text('Today, 8 Oct 2026'), findsOneWidget);
    expect(find.text('Yesterday, 7 Oct 2026'), findsOneWidget);
    expect(find.text('Showing 3 of 3 events'), findsOneWidget);
  });

  testWidgets('action chips filter on the server', (tester) async {
    final server = await _open(tester);
    await tester.tap(find.text('Voided'));
    await tester.pumpAndSettle();

    expect(server.queries.last.actions, {'voided'});
    expect(find.text('1'), findsOneWidget);
    expect(find.text('event today'), findsOneWidget);
    expect(find.text('Payment voided'), findsOneWidget);
    expect(find.text('Member created'), findsNothing);
  });

  testWidgets('cards show plain words and a short id, never the full id', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Member created'), findsOneWidget);
    expect(find.text('Payment voided'), findsOneWidget);
    expect(find.text('Created member Asha.'), findsOneWidget);
    // Time (gym-local) and short id share one line; no 24-char id anywhere.
    expect(find.textContaining('10:55 AM'), findsWidgets);
    expect(find.textContaining('#540754'), findsWidgets);
    expect(find.textContaining('6ac729553ad5eae6f6540754'), findsNothing);
  });

  testWidgets('changing the filter keeps the screen and shows skeletons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pending = Completer<ActivityLogPage>();
    final server = _Server();
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          activityLogProvider.overrideWith(
            (ref, q) => q.range == 'week'
                ? pending.future
                : Future.value(server.answer(q)),
          ),
        ],
        child: const MaterialApp(home: ActivityLogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Past 7 Days'));
    await tester.pump();
    expect(find.byKey(const Key('activity-skeleton')), findsOneWidget);
    expect(find.text('Past 7 Days'), findsOneWidget); // controls stay
    expect(find.byType(CircularProgressIndicator), findsNothing);

    pending.complete(server.answer(const ActivityLogQuery(range: 'week')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-skeleton')), findsNothing);
  });

  testWidgets('empty range shows the empty state and no Load More', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          activityLogProvider.overrideWith(
            (ref, q) async => const ActivityLogPage(
              logs: [],
              total: 0,
              page: 1,
              limit: 50,
              today: '2026-10-08',
            ),
          ),
        ],
        child: const MaterialApp(home: ActivityLogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No activity recorded'), findsOneWidget);
    expect(find.text('events today'), findsOneWidget);
    expect(find.text('Load More Events'), findsNothing);
  });

  test('query equality and filter key ignore action order and page size', () {
    const a = ActivityLogQuery(range: 'today', actions: {'voided', 'created'});
    const b = ActivityLogQuery(range: 'today', actions: {'created', 'voided'});
    const c = ActivityLogQuery(range: 'week', actions: {'created', 'voided'});
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
    expect(a.filterKey, b.filterKey);
    expect(
      const ActivityLogQuery(range: 'today', limit: 100).filterKey,
      const ActivityLogQuery(range: 'today').filterKey,
    );
  });

  test('log model: title, short id and accent colours', () {
    final l = _log('abc', action: 'refunded', entity: 'payment');
    expect(l.title, 'Payment refunded');
    expect(l.shortId, '540754');
    expect(l.dayKey, '2026-10-08');
    expect(l.timeLabel, '10:55 AM');
  });
}
