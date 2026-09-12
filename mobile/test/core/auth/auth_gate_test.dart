import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/core/api/dio_providers.dart';
import 'package:gym_manager/core/auth/auth_gate.dart';
import 'package:gym_manager/core/auth/token_storage.dart';
import 'package:gym_manager/core/settings/selected_gym_store.dart';
import 'package:gym_manager/data/gym_providers.dart';
import 'package:gym_manager/screens/login_screen.dart';

import '../../support/harness.dart';

/// A [TokenStorage] whose read never resolves, keeping the auth state pinned in
/// `unknown` so the loading branch is observable.
class _NeverTokenStorage implements TokenStorage {
  final Completer<String?> _completer = Completer<String?>();

  @override
  Future<String?> readRefreshToken() => _completer.future;

  @override
  Future<void> writeRefreshToken(String token) async {}

  @override
  Future<void> clearRefreshToken() async {}
}

/// A [SelectedGymStore] whose read throws, exercising the reconcile
/// failure-handling path.
class _ThrowingSelectedGymStore implements SelectedGymStore {
  @override
  Future<String?> read() async => throw StateError('store unavailable');

  @override
  Future<void> write(String? id) async {}
}

List<Override> _overrides({
  TokenManager? tokenManager,
  FakeAuthApi? api,
  SelectedGymStore? store,
  List<GymResponse>? gyms,
}) {
  return <Override>[
    tokenManagerProvider.overrideWithValue(
      tokenManager ?? TokenManager(FakeTokenStorage()),
    ),
    authApiProvider.overrideWithValue(api ?? FakeAuthApi()),
    selectedGymStoreProvider.overrideWithValue(store ?? FakeSelectedGymStore()),
    if (gyms != null) gymsProvider.overrideWith((ref) async => gyms),
  ];
}

void main() {
  testWidgets('shows a spinner while auth status is unknown', (
    WidgetTester tester,
  ) async {
    final TokenManager manager = TokenManager(_NeverTokenStorage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(tokenManager: manager),
        child: wrap(const AuthGate(child: Text('SHELL'))),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('SHELL'), findsNothing);
  });

  testWidgets('shows the login screen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: wrap(const AuthGate(child: Text('SHELL'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('SHELL'), findsNothing);
  });

  testWidgets('shows the child once authenticated and gyms resolve', (
    WidgetTester tester,
  ) async {
    final FakeTokenStorage storage = FakeTokenStorage()
      ..store['refresh_token'] = 'refresh-1';
    final FakeAuthApi api = FakeAuthApi()
      ..refreshResult = session(refresh: 'refresh-2');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          tokenManager: TokenManager(storage),
          api: api,
          gyms: <GymResponse>[gym('gym-1', name: 'Alpha')],
        ),
        child: wrap(const AuthGate(child: Text('SHELL'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SHELL'), findsOneWidget);
  });

  testWidgets('surfaces a reconcile failure without crashing the shell', (
    WidgetTester tester,
  ) async {
    final FakeTokenStorage storage = FakeTokenStorage()
      ..store['refresh_token'] = 'refresh-1';
    final FakeAuthApi api = FakeAuthApi()
      ..refreshResult = session(refresh: 'refresh-2');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          tokenManager: TokenManager(storage),
          api: api,
          store: _ThrowingSelectedGymStore(),
          gyms: <GymResponse>[gym('gym-1', name: 'Alpha')],
        ),
        child: wrap(const AuthGate(child: Text('SHELL'))),
      ),
    );
    await tester.pumpAndSettle();

    // Selection reconciliation failing must not become an unhandled async
    // exception nor block the authenticated shell from rendering.
    expect(find.text('SHELL'), findsOneWidget);
  });
}
