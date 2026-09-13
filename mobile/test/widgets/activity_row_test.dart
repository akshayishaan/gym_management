import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/theme/theme.dart';
import 'package:gym_manager/widgets/activity_row.dart';

import '../support/harness.dart';

ActivityListResponseLogsInner _log({
  String action = 'created',
  String entity = 'member',
  String? details,
}) {
  return ActivityListResponseLogsInner(
    id: 'log1',
    staffName: 'Alice Smith',
    action: action,
    entity: entity,
    details: details,
    createdAt: '2026-01-13T10:30:00.000Z',
  );
}

Widget _wrap(ActivityListResponseLogsInner log) {
  return wrap(
    Builder(
      builder: (BuildContext context) {
        final ThemeTokens t =
            Theme.of(context).extension<AppThemeTokens>()!.tokens;
        return ActivityRow(log: log, t: t);
      },
    ),
  );
}

void main() {
  testWidgets('renders staff name, entity and action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_log()));
    await tester.pumpAndSettle();

    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
  });

  testWidgets('renders details when present', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_log(details: 'Monthly plan added')));
    await tester.pumpAndSettle();

    expect(find.text('Monthly plan added'), findsOneWidget);
  });

  testWidgets('renders Deleted action badge', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_log(action: 'deleted')));
    await tester.pumpAndSettle();

    expect(find.text('Deleted'), findsOneWidget);
  });
}
