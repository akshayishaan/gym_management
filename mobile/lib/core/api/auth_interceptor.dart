import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import 'error_interceptor.dart';

/// Attaches `Authorization` + `X-Selected-Gym` headers and transparently
/// refreshes a stale access token once on 401.
///
/// Extends [QueuedInterceptor] so concurrent 401s are serialized through a
/// single refresh (the refresh callback is additionally single-flight in
/// `AuthController`). All callbacks are injected for testability.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenManager tokenManager,
    required String? Function() selectedGymIdReader,
    required Future<String?> Function() refreshAccessToken,
    required void Function() onLogout,
    required Dio dio,
    Dio? retryDio,
  })  : _tokenManager = tokenManager,
        _selectedGymIdReader = selectedGymIdReader,
        _refreshAccessToken = refreshAccessToken,
        _onLogout = onLogout,
        _retryDio = retryDio ?? _bareRetryDio(dio);

  static const Set<String> _authPaths = <String>{
    '/auth/login',
    '/auth/signup',
    '/auth/refresh',
  };

  final TokenManager _tokenManager;
  final String? Function() _selectedGymIdReader;
  final Future<String?> Function() _refreshAccessToken;
  final void Function() _onLogout;

  /// The [Dio] used to replay a failed request with a fresh token.
  ///
  /// It MUST be a bare [Dio] without this interceptor: replaying through the
  /// interceptor's own [QueuedInterceptor] error queue deadlocks (the replay's
  /// error is queued behind the still-in-progress original error, which is
  /// awaiting the replay). Only the [ErrorInterceptor] runs on the replay so
  /// its failure still surfaces as a normalized [DioException]/[ApiException].
  final Dio _retryDio;

  /// Builds the bare replay [Dio], borrowing [source]'s base options and
  /// transport adapter (so tests' scripted adapters see the replay) while
  /// carrying none of [source]'s interceptors.
  static Dio _bareRetryDio(Dio source) {
    final Dio retry = Dio(
      BaseOptions(
        baseUrl: source.options.baseUrl,
        contentType: source.options.contentType,
      ),
    );
    retry.httpClientAdapter = source.httpClientAdapter;
    retry.interceptors.add(ErrorInterceptor());
    return retry;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? accessToken = _tokenManager.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    final String? gymId = _selectedGymIdReader();
    if (gymId != null && gymId.isNotEmpty) {
      options.headers['X-Selected-Gym'] = gymId;
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Non-401, or an auth endpoint: nothing to refresh and no risk of a
    // logout loop — pass the error through untouched.
    if (err.response?.statusCode != 401 ||
        _isAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    // A queued burst of 401s all carry the same stale token. Once the first
    // queued refresh rotates the token, every remaining request's error still
    // references the old token — so skip a redundant refresh and replay
    // directly with the now-current token. This collapses N 401s into one
    // `POST /auth/refresh`.
    final String? requestToken = _bearerToken(err.requestOptions.headers);
    final String? currentToken = _tokenManager.accessToken;
    final bool tokenAlreadyRotated = currentToken != null &&
        currentToken.isNotEmpty &&
        requestToken != null &&
        requestToken != currentToken;

    final String? newToken =
        tokenAlreadyRotated ? currentToken : await _obtainRefreshedToken();

    if (newToken == null || newToken.isEmpty) {
      _onLogout();
      handler.next(err);
      return;
    }

    final RequestOptions retry = err.requestOptions.copyWith(
      headers: <String, dynamic>{
        ...err.requestOptions.headers,
        'Authorization': 'Bearer $newToken',
      },
    );

    try {
      final Response<dynamic> response = await _retryDio.fetch<dynamic>(retry);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      // A 401 on the retried request means the fresh token is still rejected —
      // the session is dead.
      if (retryErr.response?.statusCode == 401) {
        _onLogout();
      }
      handler.next(retryErr);
    }
  }

  Future<String?> _obtainRefreshedToken() async {
    try {
      return await _refreshAccessToken();
    } catch (_) {
      return null;
    }
  }

  bool _isAuthPath(String path) {
    final String normalized = path.startsWith('/') ? path : '/$path';
    return _authPaths.contains(normalized);
  }

  /// Extracts the bearer token from an `Authorization` header, or `null` when
  /// absent or malformed.
  String? _bearerToken(Map<String, dynamic> headers) {
    final dynamic auth = headers['Authorization'];
    if (auth is! String || !auth.startsWith('Bearer ')) return null;
    return auth.substring('Bearer '.length);
  }
}
