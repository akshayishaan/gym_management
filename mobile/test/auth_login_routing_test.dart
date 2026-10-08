import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/storage/secure_storage.dart';
import 'package:gym_manager/features/auth/application/auth_controller.dart';
import 'package:gym_manager/features/auth/data/auth_repository.dart';
import 'package:gym_manager/features/auth/domain/staff.dart';
import 'package:gym_manager/features/gym/application/active_gym_controller.dart';

/// Login no longer routes multi-gym accounts to a separate picker screen:
/// signIn auto-selects a gym (last-used when valid, otherwise the first) and
/// lands authenticated, and the user switches via the dashboard sheet.

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo(this.gymIds) : super(Dio());
  final List<String> gymIds;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      staff: Staff(id: 's1', name: 'Alex', email: email, gymIds: gymIds),
      accessToken: 'access',
      refreshToken: 'refresh',
    );
  }
}

/// In-memory [SecureStore] so the auth flow never touches the platform plugin.
class _MemoryStore extends SecureStore {
  _MemoryStore({this.selected}) : super(const FlutterSecureStorage());
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? staff;
  String? selected;

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
    accessToken = null;
    refreshToken = null;
    staff = null;
    selected = null;
  }
}

ProviderContainer _container(_FakeAuthRepo repo, _MemoryStore store) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      secureStoreProvider.overrideWithValue(store),
    ],
  );
}

/// Build the controller (which schedules rehydration) and let it settle to
/// `unauthenticated` before the test signs in.
Future<void> _settleRehydrate(ProviderContainer c) async {
  c.read(authControllerProvider.notifier);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test(
    'login with multiple gyms lands authenticated on the first gym',
    () async {
      final store = _MemoryStore();
      final container = _container(_FakeAuthRepo(const ['g1', 'g2']), store);
      addTearDown(container.dispose);
      await _settleRehydrate(container);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.com', password: 'x');

      expect(
        container.read(authControllerProvider).stage,
        AuthStage.authenticated,
      );
      expect(container.read(selectedGymIdProvider), 'g1');
      expect(store.selected, 'g1');
    },
  );

  test('login keeps the last-used gym when it is still valid', () async {
    final store = _MemoryStore(selected: 'g2');
    final container = _container(_FakeAuthRepo(const ['g1', 'g2']), store);
    addTearDown(container.dispose);
    await _settleRehydrate(container);

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.com', password: 'x');

    expect(container.read(selectedGymIdProvider), 'g2');
    expect(store.selected, 'g2');
  });

  test('login with no gyms routes to gym creation', () async {
    final store = _MemoryStore();
    final container = _container(_FakeAuthRepo(const []), store);
    addTearDown(container.dispose);
    await _settleRehydrate(container);

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.com', password: 'x');

    expect(
      container.read(authControllerProvider).stage,
      AuthStage.needsGymCreation,
    );
  });
}
