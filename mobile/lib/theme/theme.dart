import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the Material 3 [ThemeData] for the app.
///
/// The palette is populated from [ThemeTokens] (light/dark are pure data in
/// `tokens.dart`). [brightness] selects the token set and [primary] supplies
/// the per-gym `primaryColor` override; both flow through `copyWithPrimary`
/// so a gym's accent color drives the `ColorScheme.primary` and the derived
/// ring/primary-adacent tokens without hardcoding anything in widgets.
///
/// Typography: **Inter** for body, **Manrope** for display — both bundled
/// under `assets/fonts/`.
ThemeData buildAppTheme({
  required Brightness brightness,
  Color? primary,
}) {
  final ThemeTokens base = tokensFor(brightness);
  final ThemeTokens t = primary == null ? base : base.copyWithPrimary(primary);

  final ColorScheme scheme = ColorScheme.light(
    brightness: brightness,
    primary: t.primary.value,
    onPrimary: t.primary.foreground,
    secondary: t.secondary.value,
    onSecondary: t.secondary.foreground,
    error: t.destructive.value,
    onError: t.destructive.foreground,
    surface: t.card.value,
    onSurface: t.card.foreground,
    surfaceContainerHighest: t.muted.value,
    onSurfaceVariant: t.muted.foreground,
    outline: t.border,
    outlineVariant: t.border,
    tertiary: t.accent.value,
    onTertiary: t.accent.foreground,
  );

  final TextTheme textTheme = _buildTextTheme(scheme);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.background,
    textTheme: textTheme,
    fontFamily: 'Inter',

    extensions: <ThemeExtension<dynamic>>[AppThemeTokens(t)],

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: t.foreground,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: t.card.value,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radius),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: t.border,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.card.value,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}

TextTheme _buildTextTheme(ColorScheme scheme) {
  // Display typeface (Manrope) is reserved for headings/titles. Body text
  // uses Inter. Colors are resolved from the color scheme so dark mode and
  // foreground tokens are honored (no hardcoded black/white).
  const String display = 'Manrope';
  const String body = 'Inter';

  final TextTheme base = Typography.material2021().black;

  TextTheme text = TextTheme(
    // Display styles use Manrope.
    displayLarge: base.displayLarge?.copyWith(
      fontFamily: display,
      fontSize: 57,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.045 * 57,
      height: 1,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontFamily: display,
      fontSize: 45,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.045 * 45,
      height: 1,
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontFamily: display,
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.045 * 36,
      height: 1,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontFamily: display,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.045 * 32,
      height: 1,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontFamily: display,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontFamily: display,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: body,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontFamily: body,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontFamily: body,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontFamily: body,
      fontSize: 16,
      height: 1.5,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontFamily: body,
      fontSize: 14,
      height: 1.5,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontFamily: body,
      fontSize: 12,
      height: 1.4,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontFamily: body,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontFamily: body,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontFamily: body,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
  );

  // Strip the fixed black/white colors from the base theme and re-resolve
  // against our color scheme. (Do NOT pass `fontFamily` here — that would
  // clobber the Manrope display family set on the heading styles above.)
  return text.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
}

/// Theme extension that exposes the resolved [ThemeTokens] to any widget via
/// `Theme.of(context).extension<AppThemeTokens>()`.
///
/// Widgets read semantic values (e.g. `dock`, `accent`, `border`) from here
/// rather than hardcoding colors, so both per-gym primary overrides and dark
/// mode keep working.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens(this.tokens);

  final ThemeTokens tokens;

  @override
  AppThemeTokens copyWith({ThemeTokens? tokens}) =>
      AppThemeTokens(tokens ?? this.tokens);

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    // Token sets are discrete (light/dark); no animated interpolation needed.
    return t < 0.5 ? this : other;
  }
}
