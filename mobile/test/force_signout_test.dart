import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/storage/secure_storage.dart';
import 'package:gym_manager/features/auth/application/auth_controller.dart';
import 'package:gym_manager/features/auth/data/auth_repository.dart';
import 'package:gym_manager/features/auth/domain/staff.dart';

/// When the server invalidates a session (the account signed in on another
/// device, rotating the single refresh token), the app must wipe local
/// credentials and drop to `unauthenticated` with `sessionInvalidated` set —
/// not surface a generic "request failed".
class _MemoryStore extends SecureStore {
  _MemoryStore() : super(const FlutterSecureStorage());
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? staff;
  String? selected;
  bool cleared = false;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<({String? accessToken, String? refreshToken})> readTokens() async =>
      (accessToken: accessToken, refreshToken: refreshToken);

  @override
  Future<void> writeStaff(Map<String, dynamic> staff) async =>
      this.staff = staff;

  @override
  Future<Map<String, dynamic>?> readStaff() async => staff;

  @override
  Future<void> writeSelectedGymId(String gymId) async => selected = gymId;

  @override
  Future<String?> readSelectedGymId() async => selected;

  @override
  Future<void> clearSelectedGymIdFallback() async => selected = null;

  @override
  Future<bool> readWelcomeSeen() async => true;

  @override
  Future<void> writeWelcomeSeen() async {}

  @override
  Future<void> clearAll() async {
    cleared = true;
    accessToken = null;
    refreshToken = null;
    staff = null;
    selected = null;
  }
}

void main() {
  test(
    'forceSignOut wipes credentials and flags sessionInvalidated',
    () async {
      final store = _MemoryStore();
      // Seed a live-looking session.
      await store.writeTokens(accessToken: 'a', refreshToken: 'r');
      await store.writeStaff(
        Staff(id: 's1', name: 'A', email: 'a@b.c', gymIds: const ['g1'])
            .toJson(),
      );
      await store.writeSelectedGymId('g1');

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NoopAuthRepo()),
          secureStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      // Let rehydration settle to authenticated.
      container.read(authControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(authControllerProvider).stage,
        AuthStage.authenticated,
      );

      await container.read(authControllerProvider.notifier).forceSignOut();

      expect(store.cleared, isTrue, reason: 'local credentials must be wiped');
      expect(store.accessToken, isNull);
      expect(store.refreshToken, isNull);
      final state = container.read(authControllerProvider);
      expect(state.stage, AuthStage.unauthenticated);
      expect(state.sessionInvalidated, isTrue);
      expect(state.showWelcome, isFalse);
    },
  );
}

/// AuthRepository is only needed for provider override; forceSignOut never
/// touches the network.
class _NoopAuthRepo extends AuthRepository {
  _NoopAuthRepo() : super(Dio());
}
