import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/dio_client.dart';
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

  // The tests above call forceSignOut directly. These send real HTTP statuses
  // through the interceptor, which is where the sign-out has to be triggered.
  group('a 401 through the Dio interceptor', () {
    test('401 on the request and 401 on refresh signs out to login', () async {
      final adapter = _FakeAdapter(
        (o) => _json(401, '{"error":"Unauthorized"}'),
      );
      final env = await _signedIn(adapter);

      await expectLater(
        env.container.read(dioProvider).get<dynamic>('/members'),
        throwsA(isA<DioException>()),
      );

      final state = env.container.read(authControllerProvider);
      expect(state.stage, AuthStage.unauthenticated);
      expect(state.sessionInvalidated, isTrue);
      expect(env.store.cleared, isTrue);
      expect(env.store.accessToken, isNull);
      expect(env.store.refreshToken, isNull);
      expect(adapter.requests.map((r) => r.path), [
        '/members',
        '/auth/refresh',
      ]);
    });

    test(
      'a refresh that works retries the request and stays signed in',
      () async {
        final adapter = _FakeAdapter((o) {
          if (o.path == '/auth/refresh') {
            return _json(
              200,
              '{"accessToken":"new-access","refreshToken":"new-refresh"}',
            );
          }
          return o.headers['Authorization'] == 'Bearer new-access'
              ? _json(200, '{"ok":true}')
              : _json(401, '{"error":"Unauthorized"}');
        });
        final env = await _signedIn(adapter);

        final res = await env.container
            .read(dioProvider)
            .get<dynamic>('/members');

        expect(res.statusCode, 200);
        expect(env.store.accessToken, 'new-access');
        expect(env.store.refreshToken, 'new-refresh');
        expect(
          env.container.read(authControllerProvider).stage,
          AuthStage.authenticated,
        );
      },
    );

    test(
      'a server error while refreshing does not sign the user out',
      () async {
        final adapter = _FakeAdapter((o) {
          return o.path == '/auth/refresh'
              ? _json(500, '{"error":"Internal server error"}')
              : _json(401, '{"error":"Unauthorized"}');
        });
        final env = await _signedIn(adapter);

        await expectLater(
          env.container.read(dioProvider).get<dynamic>('/members'),
          throwsA(isA<DioException>()),
        );

        expect(
          env.container.read(authControllerProvider).stage,
          AuthStage.authenticated,
        );
        expect(env.store.cleared, isFalse);
      },
    );
  });
}

/// AuthRepository is only needed for provider override; forceSignOut never
/// touches the network.
class _NoopAuthRepo extends AuthRepository {
  _NoopAuthRepo() : super(Dio());
}

/// Serves canned responses so the real interceptors run without a network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);
  final ResponseBody Function(RequestOptions) _respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// A rehydrated, signed-in app whose Dio talks to [adapter].
Future<({ProviderContainer container, _MemoryStore store})> _signedIn(
  _FakeAdapter adapter,
) async {
  final store = _MemoryStore();
  await store.writeTokens(
    accessToken: 'old-access',
    refreshToken: 'old-refresh',
  );
  await store.writeStaff(
    Staff(id: 's1', name: 'A', email: 'a@b.c', gymIds: const ['g1']).toJson(),
  );
  await store.writeSelectedGymId('g1');

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_NoopAuthRepo()),
      secureStoreProvider.overrideWithValue(store),
      dioProvider.overrideWith(
        (ref) => buildDio(ref)..httpClientAdapter = adapter,
      ),
      // Production configuration, only the network is swapped out.
      bareDioProvider.overrideWith(
        (ref) => buildBareDio()..httpClientAdapter = adapter,
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(authControllerProvider.notifier);
  await Future<void>.delayed(Duration.zero);
  expect(container.read(authControllerProvider).stage, AuthStage.authenticated);
  return (container: container, store: store);
}
