import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../../data/query_scope.dart';
import '../api/dio_providers.dart';
import 'gym_settings_state.dart';
import 'selected_gym_store.dart';

/// A registered gym-scoped form: exposes whether it is dirty and how to reset
/// its fields.
class _ScopedFormRegistration {
  _ScopedFormRegistration({required this.isDirty, required this.reset});

  final bool Function() isDirty;
  final void Function() reset;
}

/// Owns the selected-gym lifecycle and the resolved [GymSettingsState].
///
/// Flutter equivalent of the web app's `GymSettingsProvider`
/// (`lib/useGymSettings.tsx`): it restores/persists the selection, resolves the
/// selected gym's settings from a cached gym list, and orchestrates gym
/// switches — including deferring a switch that would clobber a dirty form.
///
/// The selection's single source of truth is `selectedGymIdProvider` (read by
/// the [AuthInterceptor]); this controller keeps `state.selectedGymId` in sync
/// as a convenience mirror. Persistence goes through
/// `selectedGymStoreProvider`.
class GymSettingsController extends Notifier<GymSettingsState> {
  List<GymResponse> _gyms = <GymResponse>[];

  final Map<int, _ScopedFormRegistration> _forms =
      <int, _ScopedFormRegistration>{};
  int _nextFormKey = 0;

  bool _initialized = false;

  @override
  GymSettingsState build() => const GymSettingsState();

  // -- dirty-form registry ---------------------------------------------------

  /// Registers a gym-scoped form so [switchGym] can detect unsaved changes.
  /// Returns an unregister closure; forms are keyed by a monotonically
  /// increasing int so re-registering never collides.
  void Function() registerScopedForm({
    required bool Function() isDirty,
    required void Function() reset,
  }) {
    final int key = _nextFormKey++;
    _forms[key] = _ScopedFormRegistration(isDirty: isDirty, reset: reset);
    return () => _forms.remove(key);
  }

  /// Whether any registered form currently reports dirty.
  bool get hasDirtyForms => _forms.values.any((form) => form.isDirty());

  void _resetAllForms() {
    for (final _ScopedFormRegistration form in _forms.values) {
      form.reset();
    }
  }

  // -- selection lifecycle ---------------------------------------------------

  /// Restores the persisted selected gym id into the provider + state. Detail
  /// resolution (name/currency/etc.) is deferred to [reconcileGyms]. Idempotent.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final String? persisted = await ref.read(selectedGymStoreProvider).read();
    if (persisted == null) return;

    ref.read(selectedGymIdProvider.notifier).state = persisted;
    state = state.copyWith(selectedGymId: persisted);
  }

  /// Caches [gyms] and resolves the selection: the gym matching the current
  /// selection, else the first gym. Persists the selection when it changed.
  Future<void> reconcileGyms(List<GymResponse> gyms) async {
    _gyms = gyms;

    // Resolve the selection race-free with `initialize`: prefer the in-memory
    // mirror, then the persisted store (authoritative across restarts), then
    // the first gym. Reading the store directly here means a slow
    // `initialize()` can't make us clobber a persisted selection with the
    // first gym.
    final String? current = state.selectedGymId ??
        await ref.read(selectedGymStoreProvider).read() ??
        (gyms.isEmpty ? null : gyms.first.id);

    final GymResponse? selected =
        _findById(current) ?? (gyms.isEmpty ? null : gyms.first);

    if (selected == null) {
      ref.read(selectedGymIdProvider.notifier).state = null;
      state = const GymSettingsState();
      return;
    }

    ref.read(selectedGymIdProvider.notifier).state = selected.id;
    state = _stateFromGym(selected);

    if (selected.id != current) {
      await ref.read(selectedGymStoreProvider).write(selected.id);
    }
  }

  /// Switches to [gymId], deferring to [pendingGymId] when a registered form is
  /// dirty. No-op when [gymId] is the current selection or unknown.
  Future<void> switchGym(String gymId) async {
    if (gymId == state.selectedGymId) return;
    if (_findById(gymId) == null) return;

    if (hasDirtyForms) {
      state = state.copyWith(pendingGymId: gymId);
      return;
    }

    await performGymSwitch(gymId);
  }

  /// Unconditionally switches to [gymId]: resets dirty forms, persists the id,
  /// syncs the provider, refreshes state settings, and invalidates the gym
  /// scope. No-op when [gymId] is not in the cached gyms.
  Future<void> performGymSwitch(String gymId) async {
    final GymResponse? target = _findById(gymId);
    if (target == null) return;

    _resetAllForms();
    await ref.read(selectedGymStoreProvider).write(gymId);
    ref.read(selectedGymIdProvider.notifier).state = gymId;
    state = _stateFromGym(target).copyWith(pendingGymId: null);
    invalidateGymScope(ref);
  }

  /// Completes the pending switch (dialog confirmed), if any.
  Future<void> confirmPendingSwitch() async {
    final String? pending = state.pendingGymId;
    if (pending == null) return;
    await performGymSwitch(pending);
  }

  /// Abandons the pending switch (dialog dismissed).
  void cancelPendingSwitch() {
    state = state.copyWith(pendingGymId: null);
  }

  // -- helpers ---------------------------------------------------------------

  GymResponse? _findById(String? id) {
    if (id == null) return null;
    for (final GymResponse gym in _gyms) {
      if (gym.id == id) return gym;
    }
    return null;
  }

  GymSettingsState _stateFromGym(GymResponse gym) {
    return GymSettingsState(
      selectedGymId: gym.id,
      gymName: gym.name.isEmpty ? kDefaultGymName : gym.name,
      currency: gym.currency.isEmpty ? kDefaultCurrency : gym.currency,
      timezone: gym.timezone.isEmpty ? kDefaultTimezone : gym.timezone,
      primaryColor:
          gym.primaryColor.isEmpty ? kDefaultPrimaryColor : gym.primaryColor,
      address: gym.address,
      phone: gym.phone,
      email: gym.email,
    );
  }
}

final gymSettingsControllerProvider =
    NotifierProvider<GymSettingsController, GymSettingsState>(
  GymSettingsController.new,
);
