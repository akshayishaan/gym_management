import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import 'gym_theme.dart';

export 'gym_theme.dart';

/// Riverpod controller over the app's resolved [GymTheme].
///
/// Exposes `primary` (parsed per-gym color) and `brightness` so the root
/// `ConsumerWidget` can build a [ThemeData] via the theme factory. `setGym`
/// applies a per-gym `primaryColor` override; `setBrightness` follows the
/// device/system theme (or an explicit user toggle).
///
/// A `Notifier` (Riverpod 2's asynchronous-capable controller) keeps the door
/// open for Issue 14's persisted `GymSettingsProvider` equivalent.
class ThemeController extends Notifier<GymTheme> {
  @override
  GymTheme build() => const GymTheme();

  /// Applies a per-gym `primaryColor` override (hex `#RRGGBB`), or clears it
  /// when `null`/empty (falls back to the per-brightness token primary).
  void setGym({String? primaryColor}) {
    state = state.copyWith(primaryColor: primaryColor ?? '');
  }

  /// Sets explicit brightness, or clears the override (null = follow system).
  void setBrightness(Brightness? brightness) {
    state = state.copyWith(brightness: brightness);
  }

  /// The parsed primary [Color] for the current gym, or `null` when no
  /// override is set.
  Color? get primary => resolvePrimaryColor(state.primaryColor);
}

/// The canonical theme state provider.
final themeControllerProvider = NotifierProvider<ThemeController, GymTheme>(
  ThemeController.new,
);

/// The resolved primary [Color] for the current gym, or `null` when no
/// per-gym override is set (so the per-brightness token primary applies).
final primaryColorProvider = Provider<Color?>((ref) {
  final GymTheme state = ref.watch(themeControllerProvider);
  return resolvePrimaryColor(state.primaryColor);
});

/// Light [ThemeData], replacing the whole instance whenever the primary color
/// changes so the tree re-themes coherently.
final appThemeProvider = Provider<ThemeData>((ref) {
  return buildAppTheme(
    brightness: Brightness.light,
    primary: ref.watch(primaryColorProvider),
  );
});

/// Dark [ThemeData] from the same token set.
final appDarkThemeProvider = Provider<ThemeData>((ref) {
  return buildAppTheme(
    brightness: Brightness.dark,
    primary: ref.watch(primaryColorProvider),
  );
});
