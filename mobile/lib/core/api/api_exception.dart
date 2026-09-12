import 'package:dio/dio.dart';

/// The single, normalized error surfaced by every API call regardless of
/// transport or status code.
///
/// Produced by [ApiException.fromDio] and unwrapped by [asApiException] (the
/// error-normalization point used by all providers).
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.details,
    this.statusCode,
  });

  /// Human-readable message from the backend's `{error}` field, or a
  /// synthesized default for transport failures.
  final String message;

  /// Backend `details` payload (e.g. a field-error map on 422 validation).
  final dynamic details;

  /// HTTP status code, or `null` for connection-level failures.
  final int? statusCode;

  /// Toast-friendly message. Currently identical to [message]; kept as a
  /// distinct accessor so callers can decorate it (e.g. prefix the status)
  /// without changing [message]'s semantics.
  String get userMessage => message;

  /// Maps a [DioException] into an [ApiException].
  factory ApiException.fromDio(DioException e) {
    if (e.response != null) {
      return ApiException._fromResponse(e);
    }
    return ApiException(message: _networkMessage(e.type));
  }

  static ApiException _fromResponse(DioException e) {
    final Response<dynamic> response = e.response!;
    final int? statusCode = response.statusCode;
    final dynamic data = response.data;

    String message;
    dynamic details;
    if (data is Map) {
      final dynamic error = data['error'];
      message = error is String ? error : _defaultMessage(statusCode);
      details = data['details'];
    } else if (data is String) {
      // A non-JSON error body (network-layer errors sometimes return plain
      // text). Surface it verbatim when it looks like text.
      final String trimmed = data.trim();
      message = trimmed.isEmpty ? _defaultMessage(statusCode) : trimmed;
    } else {
      message = _defaultMessage(statusCode);
    }

    return ApiException(
      message: message,
      details: details,
      statusCode: statusCode,
    );
  }

  static String _defaultMessage(int? statusCode) {
    switch (statusCode) {
      case 401:
        return 'Authentication failed';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 409:
        return 'Conflict';
      case 422:
        return 'Validation failed';
      case 500:
        return 'Server error';
      default:
        return 'Request failed';
    }
  }

  static String _networkMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return 'Network error. Please check your connection.';
    }
  }

  @override
  String toString() {
    final String code = statusCode != null ? ' ($statusCode)' : '';
    return 'ApiException$code: $message';
  }
}
