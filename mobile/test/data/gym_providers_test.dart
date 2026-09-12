import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/api_exception.dart';
import 'package:gym_manager/core/api/dio_providers.dart';
import 'package:gym_manager/data/gym_providers.dart';

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

void main() {
  test('gymsProvider wraps a mismatched list body as ApiException', () async {
    // A JSON array whose items are strings → `item as Map` throws a TypeError.
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = _FakeAdapter(
      (_) => ResponseBody.fromString(
        jsonEncode(<String>['not', 'a', 'gym']),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
        },
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[dioProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(gymsProvider.future),
      throwsA(isA<ApiException>()),
    );
  });
}
