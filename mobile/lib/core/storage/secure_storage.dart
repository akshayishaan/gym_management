import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] that stores typed values.
///
/// We keep this here (rather than inlined in repositories) so we can:
///  * swap to a different backend if `flutter_secure_storage` misbehaves on
///    a given device,
///  * mock the storage in tests without touching plugin code,
///  * centralize key naming so we never typo a key.
class SecureStore {
  SecureStore(this._storage);
  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'accessToken';
  static const _kRefreshToken = 'refreshToken';
  static const _kStaffJson = 'staff';
  static const _kSelectedGymId = 'selectedGymId';
  static const _kThemeMode = 'theme_mode';

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<({String? accessToken, String? refreshToken})> readTokens() async {
    final access = await _storage.read(key: _kAccessToken);
    final refresh = await _storage.read(key: _kRefreshToken);
    return (accessToken: access, refreshToken: refresh);
  }

  Future<void> writeStaff(Map<String, dynamic> staff) async {
    await _storage.write(key: _kStaffJson, value: jsonEncode(staff));
  }

  Future<Map<String, dynamic>?> readStaff() async {
    final raw = await _storage.read(key: _kStaffJson);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeSelectedGymId(String gymId) =>
      _storage.write(key: _kSelectedGymId, value: gymId);

  Future<String?> readSelectedGymId() =>
      _storage.read(key: _kSelectedGymId);

  Future<void> writeThemeMode(String mode) =>
      _storage.write(key: _kThemeMode, value: mode);

  Future<String?> readThemeMode() =>
      _storage.read(key: _kThemeMode);

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Removes just the selected-gym-id key (e.g. when the resolved gym has
  /// been deleted server-side). Leaves the auth tokens and staff profile
  /// untouched so the user stays signed in.
  Future<void> clearSelectedGymIdFallback() async {
    await _storage.delete(key: _kSelectedGymId);
  }
}

/// Provider exposing the singleton [SecureStore] backed by the platform
/// secure storage (Android Keystore).
final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
});
