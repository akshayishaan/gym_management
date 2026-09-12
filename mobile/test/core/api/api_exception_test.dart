import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/api_exception.dart';
import 'package:gym_manager/core/api/error_interceptor.dart';

void main() {
  test('fromDio maps a backend error response to message/statusCode/details',
      () {
    final DioException err = DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 401,
        data: <String, dynamic>{'error': 'Invalid email or password'},
      ),
    );

    final ApiException api = ApiException.fromDio(err);

    expect(api.message, 'Invalid email or password');
    expect(api.statusCode, 401);
    expect(api.details, isNull);
    expect(api.userMessage, 'Invalid email or password');
  });

  test(
      'fromDio maps a connection failure to a network message with null status',
      () {
    final DioException err = DioException(
      requestOptions: RequestOptions(path: '/members'),
      type: DioExceptionType.connectionError,
    );

    final ApiException api = ApiException.fromDio(err);

    expect(api.message, 'Network error. Please check your connection.');
    expect(api.statusCode, isNull);
    expect(api.details, isNull);
  });

  test('fromDio falls back safely when response data is not a Map', () {
    final DioException err = DioException(
      requestOptions: RequestOptions(path: '/members'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/members'),
        statusCode: 500,
        data: 'plain text server error',
      ),
    );

    final ApiException api = ApiException.fromDio(err);

    expect(api.message, 'plain text server error');
    expect(api.statusCode, 500);
  });

  test('fromDio falls back to a status-based default when error is absent', () {
    final DioException err = DioException(
      requestOptions: RequestOptions(path: '/members'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/members'),
        statusCode: 403,
        data: <String, dynamic>{'error': 42}, // non-String error field
      ),
    );

    final ApiException api = ApiException.fromDio(err);

    expect(api.message, 'Forbidden');
    expect(api.statusCode, 403);
  });

  test('asApiException unwraps a DioException already carrying an ApiException',
      () {
    const ApiException inner = ApiException(
      message: 'wrapped',
      statusCode: 409,
    );
    final DioException err = DioException(
      requestOptions: RequestOptions(path: '/members'),
      error: inner,
    );

    expect(asApiException(err), same(inner));
  });

  test('asApiException passes an ApiException through unchanged', () {
    const ApiException api = ApiException(message: 'boom');
    expect(asApiException(api), same(api));
  });

  test('asApiException maps a plain DioException via fromDio', () {
    final DioException err = DioException(
      requestOptions: RequestOptions(path: '/members'),
      type: DioExceptionType.connectionError,
    );

    final ApiException api = asApiException(err);

    expect(api.message, 'Network error. Please check your connection.');
  });

  test('asApiException maps unknown errors to a generic ApiException', () {
    final ApiException api = asApiException('something went wrong');
    expect(api.message, 'something went wrong');
    expect(api.statusCode, isNull);
  });
}
