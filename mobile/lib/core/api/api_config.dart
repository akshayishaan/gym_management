/// Base URL for the gym-management API.
///
/// Read from the `--dart-define=API_BASE_URL=...` build flag, falling back to
/// the local dev server. Every [Dio] instance is seeded with this value.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
