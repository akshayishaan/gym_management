import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/app.dart';
import 'package:gym_manager/core/api/dio_providers.dart';
import 'package:gym_manager/core/auth/token_storage.dart';

/// In-memory [TokenStorage] so the app can boot without the platform-secured
/// storage plugin (which does not run under `flutter test`).
class _FakeTokenStorage implements TokenStorage {
  final Map<String, String> store = <String, String>{};

  @override
  Future<String?> readRefreshToken() async => store['refresh_token'];

  @override
  Future<void> writeRefreshToken(String token) async {
    store['refresh_token'] = token;
  }

  @override
  Future<void> clearRefreshToken() async {
    store.remove('refresh_token');
  }
}

void main() {
  Widget buildHarness() {
    return ProviderScope(
      overrides: <Override>[
        tokenManagerProvider.overrideWithValue(
          TokenManager(_FakeTokenStorage()),
        ),
      ],
      child: const GymManagerApp(),
    );
  }

  testWidgets('boots unauthenticated into the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
