import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Builds the Material 3 [ThemeData] for the RepiX app.
///
/// We start with Material 3's `colorScheme` (so all M3 components pick up our
/// brand colors automatically), then override specific styles for buttons,
/// inputs, cards, and chips to match the Figma look.
class LatoTheme {
  LatoTheme._();

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: LatoColors.primary,
      onPrimary: LatoColors.bgDark,
      secondary: LatoColors.primary,
      onSecondary: LatoColors.bgDark,
      surface: LatoColors.surfaceDark,
      onSurface: LatoColors.textPrimaryDark,
      surfaceContainer: LatoColors.surfaceDark,
      surfaceContainerHigh: LatoColors.surfaceRaisedDark,
      surfaceContainerHighest: LatoColors.surfaceHighestDark,
      onSurfaceVariant: LatoColors.textSecondaryDark,
      error: LatoColors.error,
      onError: Colors.white,
      outline: LatoColors.borderDark,
      outlineVariant: LatoColors.borderDark,
    );

    return _build(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      bg: LatoColors.bgDark,
      textPrimary: LatoColors.textPrimaryDark,
      textSecondary: LatoColors.textSecondaryDark,
    );
  }

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: LatoColors.primaryDark,
      onPrimary: Colors.white,
      secondary: LatoColors.primaryDark,
      onSecondary: Colors.white,
      surface: LatoColors.surfaceLight,
      onSurface: LatoColors.textPrimaryLight,
      surfaceContainer: LatoColors.surfaceLight,
      surfaceContainerHigh: Color(0xFFF5F5F5),
      surfaceContainerHighest: Color(0xFFEEEEEE),
      onSurfaceVariant: LatoColors.textSecondaryLight,
      error: LatoColors.error,
      onError: Colors.white,
      outline: LatoColors.borderLight,
      outlineVariant: LatoColors.borderLight,
    );

    return _build(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      bg: LatoColors.bgLight,
      textPrimary: LatoColors.textPrimaryLight,
      textSecondary: LatoColors.textSecondaryLight,
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color bg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
    );

    final textTheme = LatoText.applyLato(base.textTheme).copyWith(
      displayLarge: LatoText.style(
        size: 32,
        weight: FontWeight.w700,
        color: textPrimary,
        height: 1.2,
      ),
      displayMedium: LatoText.style(
        size: 28,
        weight: FontWeight.w700,
        color: textPrimary,
        height: 1.2,
      ),
      headlineLarge: LatoText.style(
        size: 24,
        weight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: LatoText.style(
        size: 20,
        weight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: LatoText.style(
        size: 18,
        weight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: LatoText.style(
        size: 16,
        weight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: LatoText.style(
        size: 15,
        weight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: LatoText.style(
        size: 14,
        weight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: LatoText.style(
        size: 16,
        weight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: LatoText.style(
        size: 14,
        weight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: LatoText.style(
        size: 12,
        weight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: LatoText.style(
        size: 14,
        weight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: LatoText.style(
        size: 12,
        weight: FontWeight.w600,
        color: textSecondary,
      ),
      labelSmall: LatoText.style(
        size: 11,
        weight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.4,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: LatoRadius.card,
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(LatoSizes.button),
          shape: const RoundedRectangleBorder(borderRadius: LatoRadius.button),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(LatoSizes.button),
          side: BorderSide(color: colorScheme.outline, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: LatoRadius.button),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        labelStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LatoSpacing.lg,
          vertical: LatoSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: LatoRadius.button,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: LatoRadius.button,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LatoRadius.button,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: LatoRadius.button,
          borderSide: const BorderSide(color: LatoColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: LatoRadius.button,
          borderSide: const BorderSide(color: LatoColors.error, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: colorScheme.primary,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimary, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: LatoRadius.button),
      ),
    );
  }
}
