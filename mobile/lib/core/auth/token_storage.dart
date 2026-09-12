import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistence boundary for the refresh token — the only credential that
/// survives an app restart. The access token is deliberately excluded: it
/// lives in memory only (see [TokenManager]).
abstract class TokenStorage {
  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String token);

  Future<void> clearRefreshToken();
}

/// [TokenStorage] backed by `flutter_secure_storage` (Keychain / Android
/// Keystore).
///
/// Kept deliberately thin: the plugin is platform-backed and does not run
/// under `flutter test`, so this class is only instantiated in `main.dart`
/// wiring (phase 3) and is never constructed by unit tests.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  @override
  Future<void> clearRefreshToken() => _storage.delete(key: _refreshTokenKey);
}

/// Holds the access token in memory only and delegates the refresh token to a
/// [TokenStorage].
///
/// Fully unit-testable with a fake [TokenStorage]; contains no platform code.
class TokenManager {
  TokenManager(this._storage);

  final TokenStorage _storage;

  /// The in-memory access token, or `null` when not authenticated.
  ///
  /// A public field rather than a getter/setter pair: it is a plain,
  /// synchronous, memory-only value with no logic.
  String? accessToken;

  Future<String?> readRefreshToken() => _storage.readRefreshToken();

  Future<void> writeRefreshToken(String token) =>
      _storage.writeRefreshToken(token);

  Future<void> clearRefreshToken() => _storage.clearRefreshToken();

  /// Clears both the in-memory access token and the persisted refresh token.
  Future<void> clear() async {
    accessToken = null;
    await _storage.clearRefreshToken();
  }
}
