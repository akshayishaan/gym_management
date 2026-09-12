import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/api_exception.dart';
import 'package:gym_manager/data/api_helpers.dart';

/// A minimal [HttpClientAdapter] that returns a canned JSON body.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );

Dio _dio() {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.httpClientAdapter = _FakeAdapter((_) => _json(<String, dynamic>{}));
  return dio;
}

void main() {
  test('getJson wraps a FormatException from fromJson as ApiException',
      () async {
    final Dio dio = _dio();

    await expectLater(
      getJson<Object>(
        dio,
        '/members',
        fromJson: (_) => throw const FormatException('mismatched body'),
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('getJson wraps a TypeError from fromJson as ApiException', () async {
    final Dio dio = _dio();

    await expectLater(
      getJson<Object>(
        dio,
        '/members',
        fromJson: (Map<String, dynamic> json) => json['name'] as String,
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('getJson passes through an existing ApiException unchanged', () async {
    final Dio dio = _dio();
    const ApiException expected = ApiException(message: 'already wrapped');

    await expectLater(
      getJson<Object>(
        dio,
        '/members',
        fromJson: (_) => throw expected,
      ),
      throwsA(same(expected)),
    );
  });
}
