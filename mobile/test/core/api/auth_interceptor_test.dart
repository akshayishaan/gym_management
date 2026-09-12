import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/auth_interceptor.dart';
import 'package:gym_manager/core/auth/token_storage.dart';

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeRefreshToken(String token) async {}

  @override
  Future<void> clearRefreshToken() async {}
}

/// A scripted adapter that records requests and returns the response produced
/// by the injected responder.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;
  final List<RequestOptions> requests = <RequestOptions>[];

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

ResponseBody _json(String body, int statusCode) => ResponseBody.fromString(
      body,
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );

void main() {
  test('401 on a non-auth path refreshes and retries once', () async {
    final TokenManager tokenManager = TokenManager(_FakeTokenStorage())
      ..accessToken = 'old-token';
    bool logoutCalled = false;
    int refreshCalls = 0;
    int membersCalls = 0;

    final _ScriptedAdapter adapter = _ScriptedAdapter((RequestOptions options) {
      if (options.path == '/members') {
        membersCalls++;
        if (membersCalls == 1) {
          return _json(
              jsonEncode(<String, String>{'error': 'unauthorized'}), 401);
        }
        return _json(jsonEncode(<String, bool>{'ok': true}), 200);
      }
      return _json(jsonEncode(<String, bool>{'ok': true}), 200);
    });

    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenManager: tokenManager,
        selectedGymIdReader: () => 'gym-1',
        refreshAccessToken: () async {
          refreshCalls++;
          tokenManager.accessToken = 'new-token';
          return 'new-token';
        },
        onLogout: () => logoutCalled = true,
        dio: dio,
      ),
    );

    final Response<dynamic> response = await dio.get<dynamic>('/members');

    expect(response.statusCode, 200);
    expect(refreshCalls, 1);
    expect(logoutCalled, isFalse);
    expect(adapter.requests.length, 2);
    expect(
      adapter.requests[0].headers['Authorization'],
      'Bearer old-token',
    );
    expect(
      adapter.requests[1].headers['Authorization'],
      'Bearer new-token',
    );
    expect(adapter.requests[0].headers['X-Selected-Gym'], 'gym-1');
  });

  test('401 on an auth path is not retried and does not refresh', () async {
    final TokenManager tokenManager = TokenManager(_FakeTokenStorage());
    bool logoutCalled = false;
    int refreshCalls = 0;

    final _ScriptedAdapter adapter = _ScriptedAdapter((RequestOptions options) {
      return _json(
          jsonEncode(<String, String>{'error': 'Invalid email or password'}),
          401);
    });

    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenManager: tokenManager,
        selectedGymIdReader: () => null,
        refreshAccessToken: () async {
          refreshCalls++;
          return 'new-token';
        },
        onLogout: () => logoutCalled = true,
        dio: dio,
      ),
    );

    await expectLater(
      dio.post<dynamic>(
        '/auth/login',
        data: <String, String>{'email': 'a', 'password': 'b'},
      ),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, 0);
    expect(logoutCalled, isFalse);
    expect(adapter.requests.length, 1);
  });

  test('401 with a failed refresh signals logout and passes the error through',
      () async {
    final TokenManager tokenManager = TokenManager(_FakeTokenStorage())
      ..accessToken = 'old-token';
    bool logoutCalled = false;

    final _ScriptedAdapter adapter = _ScriptedAdapter((RequestOptions options) {
      return _json(jsonEncode(<String, String>{'error': 'unauthorized'}), 401);
    });

    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenManager: tokenManager,
        selectedGymIdReader: () => null,
        refreshAccessToken: () async => null, // refresh failed
        onLogout: () => logoutCalled = true,
        dio: dio,
      ),
    );

    await expectLater(
      dio.get<dynamic>('/members'),
      throwsA(isA<DioException>()),
    );

    expect(logoutCalled, isTrue);
    expect(adapter.requests.length, 1);
  });

  test('retry that 401s again rejects (no hang) and logs out', () async {
    final TokenManager tokenManager = TokenManager(_FakeTokenStorage())
      ..accessToken = 'old-token';
    bool logoutCalled = false;
    int refreshCalls = 0;

    // Every request — the original and the replay — is rejected with 401.
    final _ScriptedAdapter adapter = _ScriptedAdapter((RequestOptions options) {
      return _json(jsonEncode(<String, String>{'error': 'unauthorized'}), 401);
    });

    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenManager: tokenManager,
        selectedGymIdReader: () => null,
        refreshAccessToken: () async {
          refreshCalls++;
          tokenManager.accessToken = 'new-token';
          return 'new-token';
        },
        onLogout: () => logoutCalled = true,
        dio: dio,
      ),
    );

    // The `.timeout` guards against a reintroduced deadlock: if the replay
    // re-entered the interceptor's own error queue, this future would never
    // complete and the test would otherwise hang.
    await expectLater(
      dio.get<dynamic>('/members').timeout(const Duration(seconds: 10)),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, 1);
    expect(logoutCalled, isTrue);
    expect(adapter.requests.length, 2); // original + exactly one replay
  });

  test('a burst of concurrent 401s triggers a single refresh', () async {
    final TokenManager tokenManager = TokenManager(_FakeTokenStorage())
      ..accessToken = 'old-token';
    bool logoutCalled = false;
    int refreshCalls = 0;

    // Requests carrying the stale token are rejected; the fresh token passes.
    final _ScriptedAdapter adapter = _ScriptedAdapter((RequestOptions options) {
      if (options.headers['Authorization'] == 'Bearer old-token') {
        return _json(
            jsonEncode(<String, String>{'error': 'unauthorized'}), 401);
      }
      return _json(jsonEncode(<String, bool>{'ok': true}), 200);
    });

    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenManager: tokenManager,
        selectedGymIdReader: () => null,
        refreshAccessToken: () async {
          refreshCalls++;
          tokenManager.accessToken = 'new-token';
          return 'new-token';
        },
        onLogout: () => logoutCalled = true,
        dio: dio,
      ),
    );

    final List<Response<dynamic>> responses = await Future.wait(
      List<Future<Response<dynamic>>>.generate(
        5,
        (_) => dio.get<dynamic>('/members'),
      ),
    );

    expect(
        responses.every((Response<dynamic> r) => r.statusCode == 200), isTrue);
    expect(refreshCalls, 1);
    expect(logoutCalled, isFalse);
  });
}
