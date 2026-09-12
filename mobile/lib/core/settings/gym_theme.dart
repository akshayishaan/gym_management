import 'package:flutter/material.dart';

/// The resolved theming inputs for the current gym + system brightness.
///
/// [primaryColor] is the gym's `#RRGGBB` hex string; `''` means "no override"
/// (use the per-brightness token primary). [brightness] is `null` to follow
/// the device color mode, or an explicit [Brightness] when the user has forced
/// light/dark. Resolved at runtime by `themeControllerProvider` — widgets never
/// compose a [ThemeData] themselves.
///
/// Light primary is `hsl(15 91% 57%)` = `#F55F2E`; dark primary is
/// `hsl(15 91% 60%)` = `#F66B3C` (see `tokens.dart`).
///
/// Introduced as a plain immutable class (no `freezed` codegen) so the
/// scaffold analyzes and runs standalone. `freezed`/`json_serializable`
/// remain declared in `pubspec.yaml`; data-layer models in Issues 14-18 will
/// adopt codegen once `build_runner` runs in CI.
@immutable
class GymTheme {
  const GymTheme({
    this.primaryColor = '',
    this.brightness,
  });

  /// Gym `#RRGGBB` hex string, or `''` when no override is set.
  final String primaryColor;

  /// Explicit light/dark override, or `null` to follow the system.
  final Brightness? brightness;

  /// Sentinel marking an absent argument in [copyWith], so `null` can be used
  /// to explicitly clear [brightness] (back to "follow system").
  static const Object _unset = Object();

  GymTheme copyWith({String? primaryColor, Object? brightness = _unset}) {
    return GymTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      brightness: identical(brightness, _unset)
          ? this.brightness
          : brightness as Brightness?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GymTheme &&
      other.primaryColor == primaryColor &&
      other.brightness == brightness;

  @override
  int get hashCode => Object.hash(primaryColor, brightness);
}

/// Parses [GymTheme.primaryColor] into a [Color], returning `null` when absent
/// (no override) or malformed — callers then fall back to the per-brightness
/// token primary. Never throws.
Color? resolvePrimaryColor(String hex) => _tryParseHex(hex);

Color? _tryParseHex(String hex) {
  var v = hex.trim();
  if (v.isEmpty) return null;
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  if (v.length != 8) return null;
  final int? parsed = int.tryParse(v, radix: 16);
  return parsed == null ? null : Color(parsed);
}
