import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/core/api/dio_providers.dart';
import 'package:gym_manager/core/settings/gym_settings_controller.dart';
import 'package:gym_manager/core/settings/gym_settings_state.dart';
import 'package:gym_manager/core/settings/selected_gym_store.dart';

class _FakeStore implements SelectedGymStore {
  String? value;
  final List<String?> writes = <String?>[];

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String? id) async {
    value = id;
    writes.add(id);
  }
}

GymResponse _gym(
  String id, {
  String name = 'Gym',
  String currency = 'INR',
  String timezone = 'Asia/Kolkata',
  String primaryColor = '#6366f1',
}) {
  return GymResponse(
    id: id,
    name: name,
    primaryColor: primaryColor,
    currency: currency,
    timezone: timezone,
    expiryReminderDays: 3,
    isActive: true,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );
}

ProviderContainer _container(_FakeStore store) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      selectedGymStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('initialize', () {
    test('restores the persisted id into provider + state', () async {
      final _FakeStore store = _FakeStore()..value = 'gym-2';
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );

      await controller.initialize();

      expect(container.read(selectedGymIdProvider), 'gym-2');
      expect(controller.state.selectedGymId, 'gym-2');
    });
  });

  group('reconcileGyms', () {
    test('selects a persisted valid id and populates settings', () async {
      final _FakeStore store = _FakeStore()..value = 'gym-2';
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );
      await controller.initialize();

      await controller.reconcileGyms(<GymResponse>[
        _gym('gym-1', name: 'Alpha'),
        _gym(
          'gym-2',
          name: 'Beta',
          currency: 'USD',
          timezone: 'America/New_York',
          primaryColor: '#111111',
        ),
      ]);

      expect(container.read(selectedGymIdProvider), 'gym-2');
      expect(controller.state.selectedGymId, 'gym-2');
      expect(controller.state.gymName, 'Beta');
      expect(controller.state.currency, 'USD');
      expect(controller.state.timezone, 'America/New_York');
      expect(controller.state.primaryColor, '#111111');
    });

    test('falls back to the first gym and persists it on an invalid id',
        () async {
      final _FakeStore store = _FakeStore()..value = 'bogus';
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );
      await controller.initialize();

      await controller.reconcileGyms(<GymResponse>[
        _gym('gym-1', name: 'Alpha'),
        _gym('gym-2', name: 'Beta'),
      ]);

      expect(container.read(selectedGymIdProvider), 'gym-1');
      expect(controller.state.selectedGymId, 'gym-1');
      expect(store.value, 'gym-1');
    });

    test('clears the selection and resets to defaults when no gyms exist',
        () async {
      final _FakeStore store = _FakeStore()..value = 'gym-1';
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );
      await controller.initialize();

      await controller.reconcileGyms(<GymResponse>[]);

      expect(container.read(selectedGymIdProvider), isNull);
      expect(controller.state.selectedGymId, isNull);
      expect(controller.state.gymName, kDefaultGymName);
    });
  });

  group('switchGym', () {
    test('switches when no forms are dirty', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );
      await controller.reconcileGyms(<GymResponse>[
        _gym('gym-1', name: 'Alpha'),
        _gym('gym-2', name: 'Beta', currency: 'EUR'),
      ]);

      await controller.switchGym('gym-2');

      expect(container.read(selectedGymIdProvider), 'gym-2');
      expect(controller.state.selectedGymId, 'gym-2');
      expect(controller.state.gymName, 'Beta');
      expect(controller.state.currency, 'EUR');
      expect(store.value, 'gym-2');
    });

    test('defers to pendingGymId when a form is dirty', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );
      await controller.reconcileGyms(<GymResponse>[
        _gym('gym-1', name: 'Alpha'),
        _gym('gym-2', name: 'Beta'),
      ]);

      int resetCalls = 0;
      controller.registerScopedForm(
        isDirty: () => true,
        reset: () => resetCalls++,
      );

      await controller.switchGym('gym-2');

      expect(controller.state.pendingGymId, 'gym-2');
      expect(container.read(selectedGymIdProvider), 'gym-1');
      expect(store.value, isNull);
      expect(resetCalls, 0);
    });

    test('confirmPendingSwitch switches and resets dirty forms', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );
      await controller.reconcileGyms(<GymResponse>[
        _gym('gym-1', name: 'Alpha'),
        _gym('gym-2', name: 'Beta'),
      ]);

      int resetCalls = 0;
      controller.registerScopedForm(
        isDirty: () => true,
        reset: () => resetCalls++,
      );

      await controller.switchGym('gym-2');
      await controller.confirmPendingSwitch();

      expect(container.read(selectedGymIdProvider), 'gym-2');
      expect(controller.state.selectedGymId, 'gym-2');
      expect(controller.state.pendingGymId, isNull);
      expect(store.value, 'gym-2');
      expect(resetCalls, 1);
    });

    test('cancelPendingSwitch clears pendingGymId without switching', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );
      await controller.reconcileGyms(<GymResponse>[
        _gym('gym-1', name: 'Alpha'),
        _gym('gym-2', name: 'Beta'),
      ]);

      controller.registerScopedForm(isDirty: () => true, reset: () {});

      await controller.switchGym('gym-2');
      controller.cancelPendingSwitch();

      expect(controller.state.pendingGymId, isNull);
      expect(container.read(selectedGymIdProvider), 'gym-1');
      expect(store.value, isNull);
    });

    test('switching to the same gym is a no-op', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );
      await controller.reconcileGyms(<GymResponse>[
        _gym('gym-1', name: 'Alpha'),
        _gym('gym-2', name: 'Beta'),
      ]);

      final int writesBefore = store.writes.length;
      await controller.switchGym('gym-1');

      expect(container.read(selectedGymIdProvider), 'gym-1');
      expect(store.writes.length, writesBefore);
    });
  });

  group('registerScopedForm', () {
    test('hasDirtyForms reflects registrations and unregister removes them',
        () {
      final _FakeStore store = _FakeStore();
      final ProviderContainer container = _container(store);
      final GymSettingsController controller = container.read(
        gymSettingsControllerProvider.notifier,
      );

      bool dirty = false;
      final void Function() unregister = controller.registerScopedForm(
        isDirty: () => dirty,
        reset: () {},
      );

      expect(controller.hasDirtyForms, isFalse);

      dirty = true;
      expect(controller.hasDirtyForms, isTrue);

      unregister();
      expect(controller.hasDirtyForms, isFalse);
    });
  });
}
