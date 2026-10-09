import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../../gym/application/active_gym_controller.dart';
import '../data/auth_repository.dart';
import '../domain/staff.dart';

/// Where the auth flow is currently. Drives the GoRouter redirect.
enum AuthStage {
  unknown,

  /// No valid session — show splash/login.
  unauthenticated,

  /// Session exists and the user has at least one gym. One gym is always
  /// selected: it is auto-picked on login/rehydrate (the last-used one when
  /// still valid, otherwise the first), and the user switches via the
  /// dashboard gym switcher sheet. There is no separate picker screen.
  authenticated,

  /// Session exists but the user has no Gym yet. Route to gym creation.
  needsGymCreation,
}

@immutable
class AuthState {
  const AuthState({
    required this.stage,
    this.staff,
    this.showWelcome = false,
    this.sessionInvalidated = false,
  });

  final AuthStage stage;
  final Staff? staff;

  /// Only meaningful while unauthenticated: route to the welcome screen
  /// (first launch after install, or right after signing out) instead of
  /// straight to login.
  final bool showWelcome;

  /// True when the previous session was invalidated server-side (signed in
  /// on another device). The login screen shows an explanatory message.
  final bool sessionInvalidated;

  static const initial = AuthState(stage: AuthStage.unknown);

  AuthState copyWith({
    AuthStage? stage,
    Staff? staff,
    bool? showWelcome,
    bool clearStaff = false,
    bool? sessionInvalidated,
  }) {
    return AuthState(
      stage: stage ?? this.stage,
      staff: clearStaff ? null : (staff ?? this.staff),
      showWelcome: showWelcome ?? this.showWelcome,
      sessionInvalidated: sessionInvalidated ?? this.sessionInvalidated,
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
      final welcomeSeen = await _store.readWelcomeSeen();
      state = AuthState(
        stage: AuthStage.unauthenticated,
        showWelcome: !welcomeSeen,
      );
      return;
    }
    final staff = Staff.fromJson(staffJson);
    if (staff.gymIds.isEmpty) {
      state = AuthState(stage: AuthStage.needsGymCreation, staff: staff);
      return;
    }
    // Make sure the persisted selection is a gym the user still has, so the
    // dashboard always opens with a valid active gym. selectedGymIdProvider
    // hydrates from the store, so writing it here is enough on cold start.
    final persisted = await _store.readSelectedGymId();
    final gymId = (persisted != null && staff.gymIds.contains(persisted))
        ? persisted
        : staff.gymIds.first;
    if (gymId != persisted) {
      await _store.writeSelectedGymId(gymId);
    }
    state = AuthState(stage: AuthStage.authenticated, staff: staff);
  }

  /// Pure stage-resolution helper: a session with no gym must create one,
  /// otherwise it is fully authenticated (a gym is always selected elsewhere).
  static AuthStage _stageFor(Staff staff) => staff.gymIds.isEmpty
      ? AuthStage.needsGymCreation
      : AuthStage.authenticated;

  Future<void> signIn({required String email, required String password}) async {
    final session = await _repo.signIn(email: email, password: password);
    await _persist(session);
    final gymIds = session.staff.gymIds;
    if (gymIds.isEmpty) {
      state = AuthState(
        stage: AuthStage.needsGymCreation,
        staff: session.staff,
      );
      return;
    }
    // Land straight on the dashboard: keep the last-used gym when it is still
    // valid, otherwise default to the first. Multi-gym users switch via the
    // dashboard gym switcher sheet; there is no separate picker screen.
    // Sync the selectedGymIdProvider (not just the store) so the right gym
    // shows even on an in-session re-login.
    final persisted = await _store.readSelectedGymId();
    final gymId = (persisted != null && gymIds.contains(persisted))
        ? persisted
        : gymIds.first;
    await ref.read(selectedGymIdProvider.notifier).select(gymId);
    state = AuthState(stage: AuthStage.authenticated, staff: session.staff);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final session = await _repo.signUp(
      name: name,
      email: email,
      password: password,
    );
    await _persist(session);
    state = AuthState(stage: _stageFor(session.staff), staff: session.staff);
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
    // clearAll wipes the flag; restore it so only this session (not the next
    // cold start) shows the welcome screen after a logout.
    await _store.writeWelcomeSeen();
    state = const AuthState(
      stage: AuthStage.unauthenticated,
      showWelcome: true,
    );
  }

  /// Server-side session invalidation (e.g. the same account signed in on
  /// another device, which rotates the single refresh token). Wipes local
  /// credentials and routes to login with an explanatory message — unlike
  /// [signOut], this is not user-initiated, so no welcome screen.
  Future<void> forceSignOut() async {
    await _store.clearAll();
    state = const AuthState(
      stage: AuthStage.unauthenticated,
      showWelcome: false,
      sessionInvalidated: true,
    );
  }

  /// Welcome screen's "Get started": remember it so later cold starts go
  /// splash -> login.
  Future<void> dismissWelcome() async {
    await _store.writeWelcomeSeen();
    state = state.copyWith(showWelcome: false);
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
      role: staff.role,
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

  /// Called after a gym is permanently deleted. Drops it from the staff's
  /// gymIds and returns the id that should now be selected: the current gym
  /// if it survived, otherwise the first remaining one. Returns null when no
  /// gyms are left, which sends the user to gym creation.
  Future<String?> onGymDeleted(String gymId) async {
    final staff = state.staff;
    if (staff == null) return null;
    final remaining = staff.gymIds.where((g) => g != gymId).toList();
    final updated = Staff(
      id: staff.id,
      name: staff.name,
      email: staff.email,
      role: staff.role,
      gymIds: remaining,
    );
    await _store.writeStaff(updated.toJson());
    if (remaining.isEmpty) {
      await _store.clearSelectedGymIdFallback();
      state = AuthState(stage: AuthStage.needsGymCreation, staff: updated);
      return null;
    }
    final selected = await _store.readSelectedGymId();
    final next = selected != null && remaining.contains(selected)
        ? selected
        : remaining.first;
    await _store.writeSelectedGymId(next);
    state = AuthState(stage: AuthStage.authenticated, staff: updated);
    return next;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Flips to `true` once the splash screen has been shown for its minimum
/// duration. The router keeps `/splash` on screen until then, so the brand
/// artwork is visible even when rehydration finishes instantly.
final splashDoneProvider = StateProvider<bool>((ref) => false);

/// `true` once the controller has rehydrated from secure storage. The router
/// waits on this to avoid flickering between login and home on cold start.
final authRehydratedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).stage != AuthStage.unknown;
});
