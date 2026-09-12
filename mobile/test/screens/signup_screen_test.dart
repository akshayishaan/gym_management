import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/core/api/dio_providers.dart';
import 'package:gym_manager/core/auth/token_storage.dart';
import 'package:gym_manager/screens/login_screen.dart';
import 'package:gym_manager/screens/signup_screen.dart';

import '../support/harness.dart';

Widget _signupHarness(FakeAuthApi api) {
  return ProviderScope(
    overrides: <Override>[
      tokenManagerProvider.overrideWithValue(TokenManager(FakeTokenStorage())),
      authApiProvider.overrideWithValue(api),
    ],
    child: wrap(const SignupScreen()),
  );
}

void main() {
  testWidgets('submitting empty fields shows validation and does not signup', (
    WidgetTester tester,
  ) async {
    final FakeAuthApi api = FakeAuthApi();
    await tester.pumpWidget(_signupHarness(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(api.signupCalls, 0);
  });

  testWidgets('successful signup returns to login with a confirmation', (
    WidgetTester tester,
  ) async {
    final FakeAuthApi api = FakeAuthApi()
      ..signupResult = SignupResponse(message: 'created');
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          tokenManagerProvider.overrideWithValue(
            TokenManager(FakeTokenStorage()),
          ),
          authApiProvider.overrideWithValue(api),
        ],
        child: wrap(const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to the signup form via the login screen link.
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(api.signupCalls, 1);
    expect(find.text('Account created. Please log in.'), findsOneWidget);
    // Back on the login screen.
    expect(find.text('Sign in'), findsWidgets);

    // Flush the snackbar's auto-dismiss timer so no timers leak.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
