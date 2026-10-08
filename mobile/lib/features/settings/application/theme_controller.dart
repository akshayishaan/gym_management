import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';

/// User-selectable theme preference. Maps onto Flutter's [ThemeMode] in
/// [materialThemeModeProvider] so the rest of the app can keep using
/// Material's enum.
enum AppThemeMode {
  dark,
  light,
  system;

  /// Persisted as lowercase strings in `SecureStore`.
  String toJson() => name;

  static AppThemeMode fromJson(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemeMode.light;
      case 'system':
        return AppThemeMode.system;
      case 'dark':
      default:
        return AppThemeMode.dark;
    }
  }

  /// Cycles dark → light → system → dark. Used by the More-menu quick toggle.
  AppThemeMode get next {
    switch (this) {
      case AppThemeMode.dark:
        return AppThemeMode.light;
      case AppThemeMode.light:
        return AppThemeMode.system;
      case AppThemeMode.system:
        return AppThemeMode.dark;
    }
  }
}

/// Persists the theme preference via [SecureStore] under the `theme_mode`
/// key. Defaults to [AppThemeMode.dark] (matching the pre-PR `main.dart`
/// behavior, so existing users see no change on first launch).
///
/// Intentionally NOT autoDispose — the preference lives for the lifetime
/// of the app session and is cheap to keep around.
class ThemeController extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    final store = ref.watch(secureStoreProvider);
    // Hydrate from storage; the synchronous default keeps the first frame
    // matching the old hard-coded dark theme so there's no flash.
    Future.microtask(() async {
      final raw = await _readRaw(store);
      final hydrated = AppThemeMode.fromJson(raw);
      if (hydrated != state) {
        state = hydrated;
      }
    });
    return AppThemeMode.dark;
  }

  Future<String?> _readRaw(SecureStore store) => store.readThemeMode();

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    final store = ref.read(secureStoreProvider);
    await store.writeThemeMode(mode.toJson());
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, AppThemeMode>(ThemeController.new);

/// Maps the persisted [AppThemeMode] to Material's [ThemeMode] so
/// `MaterialApp.router.themeMode` can consume it directly.
final materialThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(themeControllerProvider);
  switch (mode) {
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});
