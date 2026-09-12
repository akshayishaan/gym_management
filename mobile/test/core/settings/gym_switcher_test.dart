import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/core/settings/gym_settings_controller.dart';
import 'package:gym_manager/core/settings/gym_switcher.dart';
import 'package:gym_manager/core/settings/selected_gym_store.dart';
import 'package:gym_manager/data/gym_providers.dart';

import '../../support/harness.dart';

Widget _switcherHarness(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: wrap(
      const Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: GymSwitcher(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the current gym name', (WidgetTester tester) async {
    final List<GymResponse> gyms = <GymResponse>[
      gym('gym-1', name: 'Alpha'),
      gym('gym-2', name: 'Beta'),
    ];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        selectedGymStoreProvider.overrideWithValue(FakeSelectedGymStore()),
        gymsProvider.overrideWith((ref) async => gyms),
      ],
    );
    addTearDown(container.dispose);
    await container.read(gymSettingsControllerProvider.notifier).reconcileGyms(
          gyms,
        );

    await tester.pumpWidget(_switcherHarness(container));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('opens a bottom sheet listing gyms and switches on tap', (
    WidgetTester tester,
  ) async {
    final List<GymResponse> gyms = <GymResponse>[
      gym('gym-1', name: 'Alpha'),
      gym('gym-2', name: 'Beta', currency: 'EUR'),
    ];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        selectedGymStoreProvider.overrideWithValue(FakeSelectedGymStore()),
        gymsProvider.overrideWith((ref) async => gyms),
      ],
    );
    addTearDown(container.dispose);
    final GymSettingsController controller = container.read(
      gymSettingsControllerProvider.notifier,
    );
    await controller.reconcileGyms(gyms);

    await tester.pumpWidget(_switcherHarness(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GymSwitcher));
    await tester.pumpAndSettle();

    expect(find.text('YOUR GYMS'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR GYMS'), findsNothing);
    expect(controller.state.selectedGymId, 'gym-2');
    expect(controller.state.gymName, 'Beta');
  });

  testWidgets('shows a disabled "Choose gym" pill when there are no gyms', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        selectedGymStoreProvider.overrideWithValue(FakeSelectedGymStore()),
        gymsProvider.overrideWith((ref) async => <GymResponse>[]),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_switcherHarness(container));
    await tester.pumpAndSettle();

    expect(find.text('Choose gym'), findsOneWidget);

    await tester.tap(find.byType(GymSwitcher));
    await tester.pumpAndSettle();

    // No sheet opened.
    expect(find.text('YOUR GYMS'), findsNothing);
  });
}
