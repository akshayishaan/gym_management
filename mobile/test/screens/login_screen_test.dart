import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/dio_providers.dart';
import 'package:gym_manager/core/auth/token_storage.dart';
import 'package:gym_manager/screens/login_screen.dart';

import '../support/harness.dart';

Widget _harness(FakeAuthApi api) {
  return ProviderScope(
    overrides: <Override>[
      tokenManagerProvider.overrideWithValue(TokenManager(FakeTokenStorage())),
      authApiProvider.overrideWithValue(api),
    ],
    child: wrap(const LoginScreen()),
  );
}

void main() {
  testWidgets('submitting empty fields shows validation and does not login', (
    WidgetTester tester,
  ) async {
    final FakeAuthApi api = FakeAuthApi();
    await tester.pumpWidget(_harness(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(api.loginCalls, 0);
  });

  testWidgets('submitting valid credentials calls login', (
    WidgetTester tester,
  ) async {
    final FakeAuthApi api = FakeAuthApi()..loginResult = session();
    await tester.pumpWidget(_harness(api));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(api.loginCalls, 1);
  });
}
