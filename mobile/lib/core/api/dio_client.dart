import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';
import '../../features/auth/application/auth_controller.dart';
import 'api_exception.dart';

/// Base URL for the backend.
///
/// On the Android emulator, `10.0.2.2` maps to the host machine's localhost.
/// On a real device with `adb reverse tcp:3001 tcp:3001` set, `localhost` works
/// directly.
///
/// You can override at build/run time:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:3001
///   flutter run --dart-define=API_BASE=http://192.168.1.42:3001
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:3001',
);

/// Builds a configured [Dio] instance with:
///   * base URL from `--dart-define=API_BASE` (default `http://localhost:3001`),
///   * JSON content type by default,
///   * auth interceptor that attaches `Authorization: Bearer <accessToken>`,
///   * `X-Selected-Gym: <gymId>` interceptor for tenant scoping,
///   * automatic refresh on 401 with single-flight refresh (concurrent
///     requests share the same refresh future),
///   * error mapping into [ApiException] subclasses via the response interceptor.
Dio buildDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      // Don't throw on 4xx; let the response interceptor map it.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(_AuthInterceptor(ref));
  dio.interceptors.add(_ErrorMapperInterceptor());

  return dio;
}

/// Singleton Dio for the app. Override in tests with a Dio configured against
/// a `MockAdapter`.
final dioProvider = Provider<Dio>(buildDio);

/// Interceptor-free [Dio] for the token refresh call and for replaying a
/// request after a refresh. It must not share [dioProvider]'s interceptors, or
/// a 401 on the refresh call would recurse into the refresh logic.
///
/// Like [buildDio], it returns non-5xx responses instead of throwing: a 401
/// from `/auth/refresh` means the session was replaced, and has to be handled
/// as a response. Tests override this with [buildBareDio] plus a fake adapter,
/// so the real configuration is what they exercise.
Dio buildBareDio() => Dio(
  BaseOptions(
    baseUrl: kApiBase,
    validateStatus: (status) => status != null && status < 500,
  ),
);

final bareDioProvider = Provider<Dio>((ref) => buildBareDio());

/// Calls `POST /auth/refresh` with the saved refresh token. Returns the new
/// access + refresh tokens, or null if no refresh token is available or the
/// refresh itself failed.
typedef RefreshTokensFn = Future<({String accessToken, String refreshToken})?>
    Function();

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.ref);

  final Ref ref;
  Future<({String accessToken, String refreshToken})?>? _inflightRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final store = ref.read(secureStoreProvider);
    final tokens = await store.readTokens();
    final access = tokens.accessToken;
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    final gymId = await store.readSelectedGymId();
    if (gymId != null && gymId.isNotEmpty) {
      options.headers['X-Selected-Gym'] = gymId;
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.statusCode != 401) {
      handler.next(response);
      return;
    }

    // Don't try to refresh on the refresh endpoint itself.
    if (response.requestOptions.path.contains('/auth/refresh') ||
        response.requestOptions.path.contains('/auth/login') ||
        response.requestOptions.path.contains('/auth/signup')) {
      handler.next(response);
      return;
    }

    // Single-flight refresh.
    final inflight = _inflightRefresh ??= _doRefresh();
    final newTokens = await inflight;
    _inflightRefresh = null;

    if (newTokens == null) {
      handler.next(response);
      return;
    }

    // Retry the original request with the new access token.
    final retried = await _retry(
      response.requestOptions,
      newTokens.accessToken,
    );
    handler.resolve(retried);
  }

  Future<({String accessToken, String refreshToken})?> _doRefresh() async {
    final store = ref.read(secureStoreProvider);
    final tokens = await store.readTokens();
    final refresh = tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final res = await ref.read(bareDioProvider).post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      if (res.statusCode == 401) {
        // The refresh token was rejected: the session was invalidated
        // server-side (the account signed in on another device, which
        // replaces the active session). Wipe local credentials and route to
        // the login screen instead of surfacing "request failed".
        await ref.read(authControllerProvider.notifier).forceSignOut();
        return null;
      }
      if (res.statusCode != 200 || res.data == null) return null;
      final access = res.data!['accessToken'] as String?;
      final newRefresh = res.data!['refreshToken'] as String?;
      if (access == null || newRefresh == null) return null;
      await store.writeTokens(accessToken: access, refreshToken: newRefresh);
      return (accessToken: access, refreshToken: newRefresh);
    } catch (_) {
      return null;
    }
  }

  Future<Response> _retry(
    RequestOptions original,
    String accessToken,
  ) {
    return ref.read(bareDioProvider).fetch<dynamic>(
      original
          .copyWith(
            headers: Map<String, dynamic>.from(original.headers)
              ..['Authorization'] = 'Bearer $accessToken',
          )
          .copyWith(),
    );
  }
}

class _ErrorMapperInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const NetworkException(),
          type: err.type,
        ),
      );
      return;
    }
    handler.next(err);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final status = response.statusCode ?? 0;
    final data = response.data;

    if (status >= 200 && status < 300) {
      handler.next(response);
      return;
    }

    // Extract a human-readable message from the backend's NestJS error shape.
    String message = 'Request failed';
    Map<String, String> fieldErrors = const {};
    if (data is Map) {
      final m = data['message'];
      if (m is String) {
        message = m;
      } else if (m is List && m.isNotEmpty) {
        message = m.first.toString();
      }
      // Zod validation errors often look like:
      // { statusCode: 422, message: [{ path: 'email', message: 'Invalid' }] }
      if (m is List) {
        for (final entry in m) {
          if (entry is Map) {
            final path = entry['path'];
            final msg = entry['message'];
            if (path is String && msg is String) {
              fieldErrors[path] = msg;
            }
          }
        }
      }
    }

    final ApiException mapped = switch (status) {
      401 || 403 => AuthException(message),
      404 => NotFoundException(message),
      409 => ConflictException(message),
      >= 400 && < 500 => ValidationException(message, fieldErrors: fieldErrors),
      _ => ServerException(message),
    };

    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: mapped,
      ),
    );
  }
}

/// Pulls the [ApiException] out of a [DioException] (or returns the original
/// if there isn't one). Repositories use this so the rest of the app can
/// catch typed errors without depending on Dio.
ApiException toApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  return ServerException(error.toString());
}
