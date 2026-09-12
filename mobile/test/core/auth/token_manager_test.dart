import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/auth/token_storage.dart';

class _FakeTokenStorage implements TokenStorage {
  final Map<String, String> store = <String, String>{};
  int readCalls = 0;
  int writeCalls = 0;
  int clearCalls = 0;

  @override
  Future<String?> readRefreshToken() async {
    readCalls++;
    return store['refresh_token'];
  }

  @override
  Future<void> writeRefreshToken(String token) async {
    writeCalls++;
    store['refresh_token'] = token;
  }

  @override
  Future<void> clearRefreshToken() async {
    clearCalls++;
    store.remove('refresh_token');
  }
}

void main() {
  test('access token is held in memory only', () async {
    final TokenManager manager = TokenManager(_FakeTokenStorage());

    expect(manager.accessToken, isNull);
    manager.accessToken = 'access-123';
    expect(manager.accessToken, 'access-123');
    manager.accessToken = null;
    expect(manager.accessToken, isNull);
  });

  test('refresh token read/write/clear delegate to storage', () async {
    final _FakeTokenStorage storage = _FakeTokenStorage();
    final TokenManager manager = TokenManager(storage);

    expect(await manager.readRefreshToken(), isNull);

    await manager.writeRefreshToken('refresh-1');
    expect(await manager.readRefreshToken(), 'refresh-1');
    expect(storage.writeCalls, 1);
    expect(storage.readCalls, 2);

    await manager.clearRefreshToken();
    expect(await manager.readRefreshToken(), isNull);
    expect(storage.clearCalls, 1);
  });

  test('clear() clears both access and refresh tokens', () async {
    final _FakeTokenStorage storage = _FakeTokenStorage()
      ..store['refresh_token'] = 'refresh-1';
    final TokenManager manager = TokenManager(storage)
      ..accessToken = 'access-1';

    await manager.clear();

    expect(manager.accessToken, isNull);
    expect(await manager.readRefreshToken(), isNull);
    expect(storage.clearCalls, 1);
  });
}
