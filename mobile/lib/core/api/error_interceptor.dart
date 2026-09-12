import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Normalizes any [DioException] into an [ApiException] carried in the thrown
/// error's `.error` field, so callers unwrap uniformly via [asApiException].
///
/// The response/statusCode/type are preserved on the rethrown [DioException];
/// only the `.error` payload is replaced.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: ApiException.fromDio(err)));
  }
}

/// The single error-normalization point. Given any caught error, returns an
/// [ApiException]:
/// - an [ApiException] passes through unchanged;
/// - a [DioException] that already carries an [ApiException] (set by
///   [ErrorInterceptor]) unwraps it;
/// - any other [DioException] is mapped via [ApiException.fromDio];
/// - anything else becomes a generic [ApiException].
ApiException asApiException(Object? error) {
  if (error is ApiException) {
    return error;
  }
  if (error is DioException) {
    final Object? inner = error.error;
    if (inner is ApiException) {
      return inner;
    }
    return ApiException.fromDio(error);
  }
  return ApiException(message: error?.toString() ?? 'Unexpected error');
}
