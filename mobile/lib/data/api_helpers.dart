import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api/api_exception.dart';
import '../core/api/error_interceptor.dart';

/// Decodes a JSON object response body, whether dio already parsed it into a
/// [Map] or left it as a raw JSON [String].
Map<String, dynamic> decodeJsonMap(Response<dynamic> res) {
  final Object? data = res.data;
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  if (data is String) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  throw const ApiException(message: 'Unexpected response body');
}

/// Decodes a JSON array response body (see [decodeJsonMap]).
List<dynamic> decodeJsonList(Response<dynamic> res) {
  final Object? data = res.data;
  if (data is List) {
    return data;
  }
  if (data is String) {
    return jsonDecode(data) as List<dynamic>;
  }
  throw const ApiException(message: 'Unexpected response body');
}

/// GETs [path], decodes a JSON object, and maps it to [T] via [fromJson].
///
/// Every failure is normalized to an [ApiException] (via [asApiException]) so
/// the calling provider's `AsyncValue.error` always carries an [ApiException]:
/// transport failures ([DioException]) as well as a mismatched `200` body that
/// makes [decodeJsonMap]/[fromJson] throw a raw [TypeError]/[FormatException].
Future<T> getJson<T>(
  Dio dio,
  String path, {
  Map<String, dynamic>? query,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  try {
    final Response<dynamic> res = await dio.get<dynamic>(
      path,
      queryParameters: query,
    );
    return fromJson(decodeJsonMap(res));
  } catch (e) {
    throw asApiException(e);
  }
}

/// POSTs [data] to [path], decodes a JSON object, and maps it to [T].
///
/// Same normalization contract as [getJson]: every failure (transport or a
/// mismatched response body) surfaces as an [ApiException] via [asApiException].
Future<T> postJson<T>(
  Dio dio,
  String path, {
  Object? data,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  try {
    final Response<dynamic> res = await dio.post<dynamic>(path, data: data);
    return fromJson(decodeJsonMap(res));
  } catch (e) {
    throw asApiException(e);
  }
}

/// PUTs [data] to [path], decodes a JSON object, and maps it to [T].
///
/// Same normalization contract as [getJson].
Future<T> putJson<T>(
  Dio dio,
  String path, {
  Object? data,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  try {
    final Response<dynamic> res = await dio.put<dynamic>(path, data: data);
    return fromJson(decodeJsonMap(res));
  } catch (e) {
    throw asApiException(e);
  }
}

/// DELETEs [path] (optionally carrying [data]), decodes a JSON object, and
/// maps it to [T].
///
/// Same normalization contract as [getJson].
Future<T> deleteJson<T>(
  Dio dio,
  String path, {
  Object? data,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  try {
    final Response<dynamic> res = await dio.delete<dynamic>(path, data: data);
    return fromJson(decodeJsonMap(res));
  } catch (e) {
    throw asApiException(e);
  }
}
