import 'package:flutter/widgets.dart';

/// Spacing tokens. All paddings, gaps, and insets should use these instead
/// of inline numbers. Figma is set up with a 4-pt grid.
class LatoSpacing {
  LatoSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Standard page padding (Figma canvas left/right = 20).
  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: xl);

  /// Standard vertical padding inside a card.
  static const EdgeInsets cardV = EdgeInsets.symmetric(vertical: lg);

  /// Standard card padding (all sides).
  static const EdgeInsets cardAll = EdgeInsets.all(lg);
}

/// Radius tokens. Figma cards use 16-20px.
class LatoRadius {
  LatoRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius chip =
      BorderRadius.all(Radius.circular(pill));
  static const BorderRadius button =
      BorderRadius.all(Radius.circular(md));
}
