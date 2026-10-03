import 'package:flutter/material.dart';

/// RepiX brand color tokens.
///
/// Values sampled from the Figma "Lato Typography - Final Screens" design
/// (file `iDBLlEK2TLtlPpdLRFoj0U`). Names mirror the Figma variable names where
/// possible so we can trace any token back to a layer in the design.
class LatoColors {
  LatoColors._();

  // --- Brand ---
  /// Primary lime — CTA buttons, focused input borders, active tab indicator.
  static const Color primary = Color(0xFFC5F23F);

  /// Darker primary for pressed/hover states.
  static const Color primaryDark = Color(0xFFA8D42F);

  // --- Surfaces (dark theme) ---
  /// App background — near black.
  static const Color bgDark = Color(0xFF0A0A0A);

  /// Slightly lifted card / sheet surface.
  static const Color surfaceDark = Color(0xFF141414);

  /// Card border (subtle).
  static const Color borderDark = Color(0xFF262626);

  // --- Surfaces (light theme) ---
  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E5E5);

  // --- Text ---
  /// Primary text on dark.
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  /// Secondary text on dark — captions, sub-labels.
  static const Color textSecondaryDark = Color(0xFFA3A3A3);
  /// Disabled / hint text on dark.
  static const Color textTertiaryDark = Color(0xFF6B6B6B);

  /// Primary text on light.
  static const Color textPrimaryLight = Color(0xFF0A0A0A);
  static const Color textSecondaryLight = Color(0xFF525252);
  static const Color textTertiaryLight = Color(0xFFA3A3A3);

  // --- Status ---
  /// Active / success — used for "ACTIVE" chips and positive deltas.
  static const Color success = Color(0xFF4ADE80);
  /// Warning — expiring-soon chips and yellow counters.
  static const Color warning = Color(0xFFFB923C);
  /// Error — "X days left" warnings, voided payments.
  static const Color error = Color(0xFFEF4444);
  /// Info — links, secondary accents.
  static const Color info = Color(0xFF60A5FA);
}
