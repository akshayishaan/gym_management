import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../domain/staff.dart';

/// Result of a successful login/signup. Combines the parsed staff profile
/// with the issued tokens so the auth controller can persist them in one go.
class AuthSession {
  const AuthSession({
    required this.staff,
    required this.accessToken,
    required this.refreshToken,
  });
  final Staff staff;
  final String accessToken;
  final String refreshToken;
}

class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/signup',
        data: {'name': name, 'email': email, 'password': password},
      );
      if (res.statusCode == 201 && res.data != null) {
        return _parseSession(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      if (res.statusCode == 200 && res.data != null) {
        return _parseSession(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  AuthSession _parseSession(Map<String, dynamic> data) {
    final access = data['accessToken'] as String;
    final refresh = data['refreshToken'] as String;
    // Backend returns the user under `user` (legacy `staff` was a former key).
    final userJson = (data['user'] ?? data['staff']) as Map<String, dynamic>;
    final staff = Staff.fromJson(userJson);
    return AuthSession(
      staff: staff,
      accessToken: access,
      refreshToken: refresh,
    );
  }

  Object _badResponse(Response res) {
    return DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
