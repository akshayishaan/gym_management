import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/more/presentation/more_screen.dart';

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      child: const MaterialApp(home: MoreScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no dead bell, honest one-line subtitles', (tester) async {
    await _open(tester);
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(find.text('Membership plans and pricing'), findsOneWidget);
    expect(find.text('Staff actions and audit trail'), findsOneWidget);
    expect(find.textContaining('check-in'), findsNothing);
  });

  testWidgets('appearance icon and label share the pill centre', (
    tester,
  ) async {
    await _open(tester);
    await tester.scrollUntilVisible(find.text('Obsidian'), 200);
    for (final label in ['Dark', 'Light', 'System']) {
      final pill = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      final pillCx = tester.getCenter(pill.first).dx;
      expect(tester.getCenter(find.text(label)).dx, closeTo(pillCx, 1));
    }
    final darkPillCx = tester
        .getCenter(
          find
              .ancestor(of: find.text('Dark'), matching: find.byType(InkWell))
              .first,
        )
        .dx;
    expect(
      tester.getCenter(find.byIcon(Icons.dark_mode_outlined)).dx,
      closeTo(darkPillCx, 1),
    );
  });

  testWidgets('Sign Out asks first', (tester) async {
    await _open(tester);
    await tester.scrollUntilVisible(find.text('Sign Out'), 200);
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsNothing);
  });
}
