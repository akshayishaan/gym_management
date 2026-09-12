import 'package:flutter/material.dart';

/// Color-space helpers shared by the design system.
///
/// The token *values* in `tokens.dart` are stored as hex with a comment
/// noting the source `hue sat% light%` triple from `app/globals.css`
/// (converted once, at authoring time, with CSS's exact `hsl()` algorithm).
/// Widgets never compute color; they consume resolved [Color]s.
library;

/// Parses a `#RRGGBB` hex string (e.g. a gym's `primaryColor`) into a
/// [Color]. Throws [FormatException] on malformed input — callers (the
/// per-gym theme resolution) treat an invalid value as "no override".
Color hexToColor(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) {
    throw FormatException('Invalid #RRGGBB color: $hex');
  }
  return Color(int.parse(value, radix: 16));
}

/// Blends [color] with transparent at [opacity] (0..1) — equivalent to
/// `hsl(var(--x) / 0.58)` alpha in CSS.
Color withOpacity(Color color, double opacity) =>
    color.withAlpha((opacity.clamp(0, 1) * 255).round());
