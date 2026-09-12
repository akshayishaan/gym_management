import 'package:flutter/material.dart';

/// The resolved theming inputs for the current gym + system brightness.
///
/// [primaryColor] is the gym's `#RRGGBB` hex string (empty falls back to the
/// default brand orange). [brightness] follows the device color mode. This is
/// resolved at runtime by `themeControllerProvider` — widgets never compose a
/// [ThemeData] themselves.
///
/// Introduced as a plain immutable class (no `freezed` codegen) so the
/// scaffold analyzes and runs standalone. `freezed`/`json_serializable`
/// remain declared in `pubspec.yaml`; data-layer models in Issues 14-18 will
/// adopt codegen once `build_runner` runs in CI.
@immutable
class GymTheme {
  const GymTheme({
    this.primaryColor = kDefaultPrimaryColorHex,
    this.brightness = Brightness.light,
  });

  final String primaryColor;
  final Brightness brightness;

  GymTheme copyWith({String? primaryColor, Brightness? brightness}) {
    return GymTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      brightness: brightness ?? this.brightness,
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

/// Default brand primary (orange `hsl(15 91% 57%)` ≈ `#f05b3b`).
const String kDefaultPrimaryColorHex = '#f05b3b';

/// Parses [GymTheme.primaryColor] into a [Color], falling back to the default
/// orange when absent or malformed. Never throws.
Color resolvePrimaryColor(String hex) => _tryParseHex(hex) ?? defaultPrimary;

/// Default primary as a [Color] (#F05B3B).
const Color defaultPrimary = Color(0xFFF05B3B);

Color? _tryParseHex(String hex) {
  var v = hex.trim();
  if (v.isEmpty) return null;
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  if (v.length != 8) return null;
  final int? parsed = int.tryParse(v, radix: 16);
  return parsed == null ? null : Color(parsed);
}
