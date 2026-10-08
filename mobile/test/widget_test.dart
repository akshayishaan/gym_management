import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_manager/core/storage/secure_storage.dart';
import 'package:gym_manager/features/auth/presentation/splash_screen.dart';
import 'package:gym_manager/main.dart';

/// Signed-out [SecureStore] held in memory (no platform plugin).
class _SignedOutStore extends SecureStore {
  _SignedOutStore({this.welcomeSeen = false})
    : super(const FlutterSecureStorage());
  bool welcomeSeen;

  @override
  Future<({String? accessToken, String? refreshToken})> readTokens() async =>
      (accessToken: null, refreshToken: null);

  @override
  Future<Map<String, dynamic>?> readStaff() async => null;

  @override
  Future<bool> readWelcomeSeen() async => welcomeSeen;

  @override
  Future<void> writeWelcomeSeen() async => welcomeSeen = true;
}

Finder get _splashArt => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == 'assets/splash1.png',
);

Future<void> _boot(WidgetTester tester, _SignedOutStore store) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [secureStoreProvider.overrideWithValue(store)],
      child: const RepiXApp(),
    ),
  );
  // Rehydration finishes right away, but the splash is held for its minimum
  // duration.
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('splash shows only the artwork, with no Get started button', (
    tester,
  ) async {
    await _boot(tester, _SignedOutStore());

    expect(_splashArt, findsOneWidget);
    expect(find.text('Get started'), findsNothing);

    await tester.pumpAndSettle(kSplashMinDuration);
  });

  testWidgets('first launch after install goes splash -> welcome', (
    tester,
  ) async {
    await _boot(tester, _SignedOutStore());
    await tester.pumpAndSettle(kSplashMinDuration);

    expect(_splashArt, findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('later launches go splash -> login, skipping welcome', (
    tester,
  ) async {
    await _boot(tester, _SignedOutStore(welcomeSeen: true));
    expect(_splashArt, findsOneWidget);

    await tester.pumpAndSettle(kSplashMinDuration);
    expect(find.text('Get started'), findsNothing);
    expect(find.text('Login'), findsWidgets);
  });
}
