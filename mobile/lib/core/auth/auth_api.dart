import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gym_api/gym_api.dart';

import '../api/api_exception.dart';
import '../api/error_interceptor.dart';

/// The auth endpoint contract. Abstracted so [AuthController] can be unit
/// tested against a fake without a real [Dio].
abstract class AuthApi {
  Future<AuthSessionResponse> login({
    required String email,
    required String password,
  });

  Future<SignupResponse> signup({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthSessionResponse> refresh({required String refreshToken});
}

/// [AuthApi] over the bare auth [Dio] (no auth/refresh/gym interceptors).
class DioAuthApi implements AuthApi {
  DioAuthApi(this._dio);

  final Dio _dio;

  @override
  Future<AuthSessionResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/auth/login',
        data: <String, dynamic>{'email': email, 'password': password},
      );
      return AuthSessionResponse.fromJson(_decodeBody(res.data));
    } catch (e) {
      throw asApiException(e);
    }
  }

  @override
  Future<SignupResponse> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/auth/signup',
        data: <String, dynamic>{
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return SignupResponse.fromJson(_decodeBody(res.data));
    } catch (e) {
      throw asApiException(e);
    }
  }

  @override
  Future<AuthSessionResponse> refresh({required String refreshToken}) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/auth/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      return AuthSessionResponse.fromJson(_decodeBody(res.data));
    } catch (e) {
      throw asApiException(e);
    }
  }

  /// Decodes a response body that dio may or may not have already parsed.
  static Map<String, dynamic> _decodeBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    throw const ApiException(message: 'Unexpected response body');
  }
}
