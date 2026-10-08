import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/gym/application/active_gym_controller.dart';
import 'package:gym_manager/features/gym/domain/gym.dart';
import 'package:gym_manager/features/gym/presentation/gym_switcher_sheet.dart';

class _SelectedGym extends SelectedGymIdNotifier {
  @override
  String? build() => 'g1';
}

const _gym = Gym(
  id: 'g1',
  name: 'Muscle Gym',
  primaryColor: '#C5F23F',
  currency: 'INR',
  timezone: 'Asia/Kolkata',
  expiryReminderDays: 7,
  isActive: true,
);

Widget _host(Completer<List<Gym>> completer) {
  return ProviderScope(
    overrides: [
      selectedGymIdProvider.overrideWith(_SelectedGym.new),
      userGymsProvider.overrideWith((ref) => completer.future),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: GymSwitcherSheet(),
        ),
      ),
    ),
  );
}

double _sheetHeight(WidgetTester tester) =>
    tester.getSize(find.byType(GymSwitcherSheet)).height;

void main() {
  testWidgets('sheet height is the same while loading and once loaded', (
    tester,
  ) async {
    final completer = Completer<List<Gym>>();
    await tester.pumpWidget(_host(completer));
    final loading = _sheetHeight(tester);

    completer.complete([_gym]);
    await tester.pumpAndSettle();
    final loaded = _sheetHeight(tester);

    expect(find.text('Muscle Gym'), findsOneWidget);
    expect(loaded, closeTo(loading, 0.5));
  });

  testWidgets('sheet height is the same while loading and on error', (
    tester,
  ) async {
    final completer = Completer<List<Gym>>();
    await tester.pumpWidget(_host(completer));
    final loading = _sheetHeight(tester);

    completer.completeError(Exception('boom'));
    await tester.pumpAndSettle();
    final errored = _sheetHeight(tester);

    expect(find.text('Retry'), findsOneWidget);
    expect(errored, closeTo(loading, 0.5));
  });

  testWidgets('sheet height is the same while loading and when empty', (
    tester,
  ) async {
    final completer = Completer<List<Gym>>();
    await tester.pumpWidget(_host(completer));
    final loading = _sheetHeight(tester);

    completer.complete(const []);
    await tester.pumpAndSettle();
    final empty = _sheetHeight(tester);

    expect(find.text('No gyms available'), findsOneWidget);
    expect(empty, closeTo(loading, 0.5));
  });
}
