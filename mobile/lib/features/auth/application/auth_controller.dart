import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/staff.dart';

/// Where the auth flow is currently. Drives the GoRouter redirect.
enum AuthStage {
  unknown,

  /// No valid session — show splash/login.
  unauthenticated,

  /// Session exists; user has at least one gym AND we know which one is
  /// selected (or only one gym exists and we auto-picked it).
  authenticated,

  /// Session exists but the user has no Gym yet. Route to gym creation.
  needsGymCreation,

  /// Session exists, user has 2+ gyms, but none is currently selected.
  /// Route to the gym picker.
  needsGymSelection,
}

@immutable
class AuthState {
  const AuthState({
    required this.stage,
    this.staff,
  });

  final AuthStage stage;
  final Staff? staff;

  static const initial = AuthState(stage: AuthStage.unknown);

  AuthState copyWith({AuthStage? stage, Staff? staff, bool clearStaff = false}) {
    return AuthState(
      stage: stage ?? this.stage,
      staff: clearStaff ? null : (staff ?? this.staff),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;
  late final SecureStore _store;

  @override
  AuthState build() {
    _repo = ref.watch(authRepositoryProvider);
    _store = ref.watch(secureStoreProvider);
    // Kick off rehydration asynchronously. The router waits on
    // `authRehydratedProvider` before making its first redirect decision.
    Future.microtask(_rehydrate);
    return AuthState.initial;
  }

  Future<void> _rehydrate() async {
    final tokens = await _store.readTokens();
    final staffJson = await _store.readStaff();
    if (tokens.accessToken == null || staffJson == null) {
      state = const AuthState(stage: AuthStage.unauthenticated);
      return;
    }
    final staff = Staff.fromJson(staffJson);
    final selectedGym = await _store.readSelectedGymId();
    state = AuthState(
      stage: _stageFor(staff: staff, selectedGymId: selectedGym),
      staff: staff,
    );
  }

  /// Pure stage-resolution helper. Centralized so the rules are easy to audit
  /// and so the router's redirect can mirror them.
  static AuthStage _stageFor({
    required Staff staff,
    required String? selectedGymId,
  }) {
    if (staff.gymIds.isEmpty) return AuthStage.needsGymCreation;
    if (selectedGymId == null || !staff.gymIds.contains(selectedGymId)) {
      return staff.gymIds.length == 1
          ? AuthStage.authenticated // auto-pick the only gym below
          : AuthStage.needsGymSelection;
    }
    return AuthStage.authenticated;
  }

  Future<void> signIn({required String email, required String password}) async {
final session = await _repo.signIn(email: email, password: password);
    await _persist(session);
    final nextStage = _stageFor(staff: session.staff, selectedGymId: null);
state = AuthState(
      stage: nextStage,
      staff: session.staff,
    );
    // If the user has exactly one gym, auto-select it.
    if (session.staff.gymIds.length == 1) {
      await onGymSelected(session.staff.gymIds.first);
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final session =
        await _repo.signUp(name: name, email: email, password: password);
    await _persist(session);
    state = AuthState(
      stage: _stageFor(staff: session.staff, selectedGymId: null),
      staff: session.staff,
    );
  }

  Future<void> _persist(AuthSession session) async {
    await _store.writeTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _store.writeStaff(session.staff.toJson());
  }

  Future<void> signOut() async {
    await _store.clearAll();
    state = const AuthState(stage: AuthStage.unauthenticated);
  }

  /// Called when the user picks an active gym, or when they create their
  /// first gym. Updates the cached staff.gymIds and persists the chosen one.
  Future<void> onGymSelected(String gymId) async {
    final staff = state.staff;
    if (staff == null) return;
    final updatedGyms = staff.gymIds.contains(gymId)
        ? staff.gymIds
        : [...staff.gymIds, gymId];
    final updated = Staff(
      id: staff.id,
      name: staff.name,
      email: staff.email,
      gymIds: updatedGyms,
    );
    await _store.writeStaff(updated.toJson());
    await _store.writeSelectedGymId(gymId);
    state = state.copyWith(staff: updated, stage: AuthStage.authenticated);
  }

  /// Called by the gym-creation flow after the backend returns a new gym.
  /// Adds the id to the staff's gymIds, auto-selects it, and transitions to
  /// the authenticated stage.
  Future<void> onGymCreated(String gymId) async {
    await onGymSelected(gymId);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// `true` once the controller has rehydrated from secure storage. The router
/// waits on this to avoid flickering between login and home on cold start.
final authRehydratedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).stage != AuthStage.unknown;
});
