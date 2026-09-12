import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/token_storage.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// The app's [TokenManager]. Overridden in `main.dart` (phase 3) with a
/// [SecureTokenStorage]-backed instance; tests override it with a fake.
final tokenManagerProvider = Provider<TokenManager>((ref) {
  throw UnimplementedError(
    'Override tokenManagerProvider in main.dart with a SecureTokenStorage-backed TokenManager',
  );
});

/// Single source of truth for the currently selected gym id. Phase 2's
/// GymSettings controller writes to this; the [AuthInterceptor] reads it.
final selectedGymIdProvider = StateProvider<String?>((ref) => null);

/// [AuthApi] implementation bound to the bare auth [Dio]. Overridable with a
/// fake in controller tests.
final authApiProvider = Provider<AuthApi>((ref) {
  return DioAuthApi(ref.watch(authDioProvider));
});

/// Bare [Dio] for auth endpoints only: JSON base options + the
/// [ErrorInterceptor]. No auth header, no refresh, no gym header.
final authDioProvider = Provider<Dio>((ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: Headers.jsonContentType,
    ),
  );
  dio.interceptors.add(ErrorInterceptor());
  return dio;
});

/// Main [Dio] for authenticated, gym-scoped requests.
///
/// The [AuthInterceptor] needs the [TokenManager], the selected gym, and a way
/// to refresh + signal logout. To avoid a build-time cycle ([AuthController]
/// depends on [authDioProvider]; the interceptor needs the controller), the
/// controller is read lazily inside the interceptor callbacks — never during
/// this provider's build.
final dioProvider = Provider<Dio>((ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenManager: ref.watch(tokenManagerProvider),
      selectedGymIdReader: () => ref.read(selectedGymIdProvider),
      refreshAccessToken: () =>
          ref.read(authControllerProvider.notifier).refreshAccessToken(),
      onLogout: () {
        // Fire-and-forget: the interceptor must not await the logout.
        ref.read(authControllerProvider.notifier).logout();
      },
      dio: dio,
    ),
  );
  dio.interceptors.add(ErrorInterceptor());

  return dio;
});
