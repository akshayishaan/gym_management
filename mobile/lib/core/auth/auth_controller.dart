import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../api/api_exception.dart';
import '../api/dio_providers.dart';
import 'auth_api.dart';
import 'auth_state.dart';
import 'token_storage.dart';

/// Authenticates the user and owns the [AuthState] lifecycle.
///
/// Dependencies are constructor-injected (for direct unit testing) and fall
/// back to `ref.read(...)` when built by [authControllerProvider] with no
/// arguments — i.e. the provider builds the controller from `ref`. The access
/// token is held by [TokenManager] (memory only); [AuthState] carries only
/// status + user.
class AuthController extends Notifier<AuthState> {
  AuthController({
    TokenManager? tokenManager,
    AuthApi? authApi,
    void Function()? onLogout,
  })  : _tokenManager = tokenManager,
        _authApi = authApi,
        _onLogout = onLogout;

  final TokenManager? _tokenManager;
  final AuthApi? _authApi;
  final void Function()? _onLogout;

  Future<AuthSessionResponse>? _inFlightRefresh;
  bool _restoreAttempted = false;

  TokenManager get _tokens => _tokenManager ?? ref.read(tokenManagerProvider);

  AuthApi get _api => _authApi ?? ref.read(authApiProvider);

  @override
  AuthState build() {
    _scheduleRestore();
    return const AuthState();
  }

  void _scheduleRestore() {
    if (_restoreAttempted) return;
    _restoreAttempted = true;
    Future<void>.microtask(restoreSession);
  }

  /// Attempts to restore a persisted session from the refresh token.
  Future<void> restoreSession() async {
    if (state.status == AuthStatus.authenticated) return;

    final String? refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // A concurrent login may have authenticated the user while this await
      // was in flight; don't clobber it.
      if (state.status != AuthStatus.authenticated) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
      return;
    }

    try {
      await refreshSession();
    } on Exception {
      // refreshSession already cleared tokens and set `unauthenticated`.
    }
  }

  /// Refreshes the access/refresh token pair. Single-flight: concurrent
  /// callers share the same in-flight future, so the backend sees one refresh.
  Future<AuthSessionResponse> refreshSession() {
    return _inFlightRefresh ??= _doRefresh();
  }

  Future<AuthSessionResponse> _doRefresh() async {
    try {
      final String? refreshToken = await _tokens.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const ApiException(message: 'No refresh token available');
      }

      final AuthSessionResponse session = await _api.refresh(
        refreshToken: refreshToken,
      );
      await _tokens.writeRefreshToken(session.refreshToken);
      _tokens.accessToken = session.accessToken;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: AuthUser.fromSessionUser(session.user),
      );
      return session;
    } catch (_) {
      await _tokens.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    } finally {
      _inFlightRefresh = null;
    }
  }

  /// Returns just the refreshed access token (or `null` on failure) for the
  /// interceptor. Shares the single-flight future with [refreshSession] and
  /// never rethrows.
  Future<String?> refreshAccessToken() async {
    try {
      final AuthSessionResponse session = await refreshSession();
      return session.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final AuthSessionResponse session = await _api.login(
      email: email,
      password: password,
    );
    await _tokens.writeRefreshToken(session.refreshToken);
    _tokens.accessToken = session.accessToken;
    state = AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser.fromSessionUser(session.user),
    );
  }

  /// Registers a new account. Does NOT create a session — the user must log in
  /// afterwards. Returns the backend's `{message}` for the UI to surface.
  Future<SignupResponse> signup({
    required String name,
    required String email,
    required String password,
  }) {
    return _api.signup(name: name, email: email, password: password);
  }

  Future<void> logout() async {
    await _tokens.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
    _onLogout?.call();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
