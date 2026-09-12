import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/app.dart';

void main() {
  Widget buildHarness() => const ProviderScope(child: GymManagerApp());

  testWidgets('shell renders the dock, top bar and Today content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    // Let the AppScreen stagger animation settle (420ms + 180ms max delay).
    await tester.pumpAndSettle();

    // Top bar brand + title.
    expect(find.text('Gym Manager'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    // Bottom dock tabs.
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Today placeholder surface content.
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('tapping a dock tab switches the visible screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();

    expect(find.text('Member search, status filters and the member card list arrive with Issues 15.'), findsOneWidget);
  });

  testWidgets('renders without exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
