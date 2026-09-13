import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/widgets/gym_avatar.dart';

import '../support/harness.dart';

void main() {
  testWidgets('renders fallback initial when no logo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const GymAvatar(name: 'FitZone Gym')));
    await tester.pumpAndSettle();

    expect(find.text('F'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('renders first letter uppercase for lowercase name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const GymAvatar(name: 'alpha')));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('falls back to G for empty name', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const GymAvatar(name: '')));
    await tester.pumpAndSettle();

    expect(find.text('G'), findsOneWidget);
  });

  testWidgets('renders image when logo is a valid base64 data URL', (
    WidgetTester tester,
  ) async {
    const String png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    await tester.pumpWidget(
      wrap(const GymAvatar(name: 'FitZone Gym', logo: 'data:image/png;base64,$png')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('falls back to initial for invalid base64 logo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(const GymAvatar(name: 'FitZone Gym', logo: 'not-base64!!!')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.text('F'), findsOneWidget);
  });
}
