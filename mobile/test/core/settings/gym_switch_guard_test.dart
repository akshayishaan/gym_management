import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/core/settings/gym_settings_controller.dart';
import 'package:gym_manager/core/settings/gym_switch_guard.dart';
import 'package:gym_manager/core/settings/selected_gym_store.dart';

import '../../support/harness.dart';

/// Builds a [GymSwitchGuard] whose controller has already been driven into a
/// pending-switch state (`gym-2` awaiting confirmation while `gym-1` is
/// selected and a form is dirty).
Future<ProviderContainer> pumpPendingGuard(WidgetTester tester) async {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      selectedGymStoreProvider.overrideWithValue(FakeSelectedGymStore()),
    ],
  );
  addTearDown(container.dispose);

  final GymSettingsController controller = container.read(
    gymSettingsControllerProvider.notifier,
  );
  await controller.reconcileGyms(<GymResponse>[
    gym('gym-1', name: 'Alpha'),
    gym('gym-2', name: 'Beta', currency: 'EUR'),
  ]);
  controller.registerScopedForm(isDirty: () => true, reset: () {});
  await controller.switchGym('gym-2');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: wrap(const GymSwitchGuard(child: Text('CHILD'))),
    ),
  );
  await tester.pump();

  return container;
}

void main() {
  testWidgets('shows the confirm dialog when a switch is pending', (
    WidgetTester tester,
  ) async {
    await pumpPendingGuard(tester);

    expect(find.text('Discard changes and switch Gym?'), findsOneWidget);
    expect(find.text('Keep editing'), findsOneWidget);
    expect(find.text('Discard and switch'), findsOneWidget);
    // The child is still rendered underneath the overlay.
    expect(find.text('CHILD'), findsOneWidget);
  });

  testWidgets('"Keep editing" cancels the pending switch', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpPendingGuard(tester);
    final GymSettingsController controller = container.read(
      gymSettingsControllerProvider.notifier,
    );

    await tester.tap(find.text('Keep editing'));
    await tester.pump();

    expect(controller.state.pendingGymId, isNull);
    expect(controller.state.selectedGymId, 'gym-1');
    expect(find.text('Discard changes and switch Gym?'), findsNothing);
  });

  testWidgets('"Discard and switch" completes the pending switch', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpPendingGuard(tester);
    final GymSettingsController controller = container.read(
      gymSettingsControllerProvider.notifier,
    );

    await tester.tap(find.text('Discard and switch'));
    await tester.pump();

    expect(controller.state.pendingGymId, isNull);
    expect(controller.state.selectedGymId, 'gym-2');
    expect(controller.state.currency, 'EUR');
    expect(find.text('Discard changes and switch Gym?'), findsNothing);
  });
}
