import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/core/api/api_exception.dart';
import 'package:gym_manager/core/api/dio_providers.dart';
import 'package:gym_manager/core/auth/auth_api.dart';
import 'package:gym_manager/core/auth/auth_controller.dart';
import 'package:gym_manager/core/auth/auth_state.dart';
import 'package:gym_manager/core/auth/token_storage.dart';

class _FakeTokenStorage implements TokenStorage {
  final Map<String, String> store = <String, String>{};

  @override
  Future<String?> readRefreshToken() async => store['refresh_token'];

  @override
  Future<void> writeRefreshToken(String token) async {
    store['refresh_token'] = token;
  }

  @override
  Future<void> clearRefreshToken() async {
    store.remove('refresh_token');
  }
}

class _FakeAuthApi implements AuthApi {
  int refreshCalls = 0;
  int loginCalls = 0;

  AuthSessionResponse? refreshResult;
  AuthSessionResponse? loginResult;
  Object? refreshError;

  Completer<void>? refreshGate;

  @override
  Future<AuthSessionResponse> refresh({required String refreshToken}) async {
    refreshCalls++;
    if (refreshGate != null) await refreshGate!.future;
    if (refreshError != null) throw refreshError!;
    return refreshResult!;
  }

  @override
  Future<AuthSessionResponse> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return loginResult!;
  }

  @override
  Future<SignupResponse> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }
}

AuthSessionResponse _session(String access, String refresh) {
  return AuthSessionResponse(
    accessToken: access,
    refreshToken: refresh,
    user: AuthSessionResponseUser(
      id: 'u1',
      name: 'Test User',
      email: 'user@example.com',
      role: 'admin',
      gymIds: <String>['g1'],
    ),
  );
}

ProviderContainer _container({
  required _FakeAuthApi api,
  required _FakeTokenStorage storage,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      tokenManagerProvider.overrideWithValue(TokenManager(storage)),
      authApiProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() async {
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('login stores access + refresh tokens and sets authenticated', () async {
    final _FakeTokenStorage storage = _FakeTokenStorage();
    final _FakeAuthApi api = _FakeAuthApi()
      ..loginResult = _session('access-1', 'refresh-1');
    final ProviderContainer container = _container(api: api, storage: storage);
    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );

    await _settle(); // let the startup restore finish (no token -> unauthenticated)
    await controller.login(email: 'user@example.com', password: 'pw');

    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.user?.email, 'user@example.com');
    expect(container.read(tokenManagerProvider).accessToken, 'access-1');
    expect(storage.store['refresh_token'], 'refresh-1');
    expect(api.loginCalls, 1);
  });

  test('restoreSession with no refresh token -> unauthenticated', () async {
    final _FakeTokenStorage storage = _FakeTokenStorage();
    final _FakeAuthApi api = _FakeAuthApi();
    final ProviderContainer container = _container(api: api, storage: storage);
    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );

    await _settle();

    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(api.refreshCalls, 0);
  });

  test('restoreSession with a valid token -> authenticated (single refresh)',
      () async {
    final _FakeTokenStorage storage = _FakeTokenStorage()
      ..store['refresh_token'] = 'refresh-1';
    final _FakeAuthApi api = _FakeAuthApi()
      ..refreshResult = _session('access-2', 'refresh-2');
    final ProviderContainer container = _container(api: api, storage: storage);
    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );

    await _settle();

    expect(controller.state.status, AuthStatus.authenticated);
    expect(container.read(tokenManagerProvider).accessToken, 'access-2');
    expect(storage.store['refresh_token'], 'refresh-2'); // rotated
    expect(api.refreshCalls, 1);
  });

  test('restoreSession refresh failure -> unauthenticated + cleared', () async {
    final _FakeTokenStorage storage = _FakeTokenStorage()
      ..store['refresh_token'] = 'refresh-1';
    final _FakeAuthApi api = _FakeAuthApi()
      ..refreshError = const ApiException(
        message: 'Invalid refresh token',
        statusCode: 401,
      );
    final ProviderContainer container = _container(api: api, storage: storage);
    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );

    await _settle();

    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(storage.store.containsKey('refresh_token'), isFalse);
    expect(container.read(tokenManagerProvider).accessToken, isNull);
  });

  test('two concurrent refreshSession calls share a single refresh', () async {
    final _FakeTokenStorage storage = _FakeTokenStorage();
    final _FakeAuthApi api = _FakeAuthApi()
      ..refreshResult = _session('access-2', 'refresh-2')
      ..refreshGate = Completer<void>();
    final ProviderContainer container = _container(api: api, storage: storage);
    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );

    await _settle(); // startup restore with empty token -> no refresh call.

    storage.store['refresh_token'] = 'refresh-1';

    final Future<AuthSessionResponse> first = controller.refreshSession();
    final Future<AuthSessionResponse> second = controller.refreshSession();

    api.refreshGate!.complete();
    await Future.wait(<Future<AuthSessionResponse>>[first, second]);

    expect(api.refreshCalls, 1);
    expect(controller.state.status, AuthStatus.authenticated);
  });

  test('logout clears tokens and sets unauthenticated', () async {
    final _FakeTokenStorage storage = _FakeTokenStorage()
      ..store['refresh_token'] = 'refresh-1';
    final _FakeAuthApi api = _FakeAuthApi();
    final ProviderContainer container = _container(api: api, storage: storage);
    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );
    container.read(tokenManagerProvider).accessToken = 'access-1';

    await controller.logout();

    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(container.read(tokenManagerProvider).accessToken, isNull);
    expect(storage.store.containsKey('refresh_token'), isFalse);
  });
}
