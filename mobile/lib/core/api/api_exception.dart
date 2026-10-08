/// Errors thrown by API calls. Mapped from NestJS exception filter responses
/// and Dio transport errors.
sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Network unreachable, DNS failure, TLS error, timeout.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Network unreachable']);
}

/// 401/403 — credentials invalid or session expired.
class AuthException extends ApiException {
  const AuthException([super.message = 'Not authenticated']);
}

/// 4xx with a validation message (e.g. duplicate email, password too short).
class ValidationException extends ApiException {
  const ValidationException(super.message, {this.fieldErrors = const {}});
  final Map<String, String> fieldErrors;
}

/// 5xx or other unexpected server failure.
class ServerException extends ApiException {
  const ServerException([super.message = 'Server error']);
}

/// 404 — resource not found.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found']);
}

/// 409 — conflict (e.g. trying to mutate a deleted entity).
class ConflictException extends ApiException {
  const ConflictException(super.message);
}
