import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/settings/theme_controller.dart';
import 'package:gym_manager/widgets/theme_toggle.dart';

import '../support/harness.dart';

void main() {
  testWidgets('renders Appearance label and light subtitle by default', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrap(const Scaffold(body: ThemeToggle())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light theme'), findsOneWidget);
  });

  testWidgets('toggling switch sets dark brightness', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrap(const Scaffold(body: ThemeToggle())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(
      container.read(themeControllerProvider).brightness,
      Brightness.dark,
    );
  });
}
