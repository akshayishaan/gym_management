import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for the RepiX app.
///
/// All text styles use **Lato** (loaded via `google_fonts` package so we don't
/// have to bundle the .ttf files). The scale is named after the Figma text
/// style names where possible: Display, Heading 1/2, Body, Caption.
class LatoText {
  LatoText._();

  /// Apply Lato to an existing TextTheme. Use this with
  /// `Theme.of(context).textTheme` to keep the rest of Material 3 styling
  /// (color, weight hints) while swapping the font.
  static TextTheme applyLato(TextTheme base) {
    return GoogleFonts.latoTextTheme(base);
  }

  /// A pure Lato text style. Use for one-off text that doesn't fit the
  /// Material text theme.
  static TextStyle style({
    required double size,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.lato(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
