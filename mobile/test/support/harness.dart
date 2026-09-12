import 'package:flutter/material.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/core/auth/auth_api.dart';
import 'package:gym_manager/core/auth/token_storage.dart';
import 'package:gym_manager/core/settings/selected_gym_store.dart';
import 'package:gym_manager/theme/theme.dart';

/// In-memory [TokenStorage] so widgets/controllers can boot without the
/// platform-secured storage plugin (which does not run under `flutter test`).
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([Map<String, String>? initial])
      : store = initial ?? <String, String>{};

  final Map<String, String> store;

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

/// In-memory [SelectedGymStore] avoiding `shared_preferences`.
class FakeSelectedGymStore implements SelectedGymStore {
  FakeSelectedGymStore([this.value]);

  String? value;
  final List<String?> writes = <String?>[];

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String? id) async {
    value = id;
    writes.add(id);
  }
}

/// Configurable [AuthApi] fake. Set a result or an error before the call; the
/// corresponding `*Calls` counter records invocations.
class FakeAuthApi implements AuthApi {
  AuthSessionResponse? loginResult;
  AuthSessionResponse? refreshResult;
  SignupResponse? signupResult;
  Object? loginError;
  Object? signupError;

  int loginCalls = 0;
  int signupCalls = 0;

  @override
  Future<AuthSessionResponse> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<AuthSessionResponse> refresh({required String refreshToken}) async {
    return refreshResult!;
  }

  @override
  Future<SignupResponse> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    signupCalls++;
    if (signupError != null) throw signupError!;
    return signupResult!;
  }
}

AuthSessionResponse session({
  String access = 'access',
  String refresh = 'refresh',
  String gymId = 'gym-1',
}) {
  return AuthSessionResponse(
    accessToken: access,
    refreshToken: refresh,
    user: AuthSessionResponseUser(
      id: 'u1',
      name: 'Test User',
      email: 'user@example.com',
      role: 'admin',
      gymIds: <String>[gymId],
    ),
  );
}

GymResponse gym(
  String id, {
  String name = 'Gym',
  String currency = 'INR',
  String timezone = 'Asia/Kolkata',
  String primaryColor = '#6366f1',
}) {
  return GymResponse(
    id: id,
    name: name,
    primaryColor: primaryColor,
    currency: currency,
    timezone: timezone,
    expiryReminderDays: 3,
    isActive: true,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );
}

/// Wraps [child] in a [MaterialApp] themed with the light token set, so
/// `Theme.of(context).extension<AppThemeTokens>()` resolves for widgets.
Widget wrap(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(brightness: Brightness.light),
    home: child,
  );
}
