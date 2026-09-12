import 'package:flutter/material.dart';

/// A single semantic color that carries an implicit foreground pairing.
///
/// Mirrors the Tailwind `shadcn/ui` HSL token convention from the web app:
/// every token is either a bare color or a `*-foreground` pairing.
@immutable
class TokenColor {
  const TokenColor(this.value, this.foreground);

  /// Base color value (e.g. `card`, `primary`).
  final Color value;

  /// Paired foreground (e.g. `card-foreground`, `primary-foreground`).
  final Color foreground;
}

/// The full set of semantic design tokens for a single brightness.
///
/// All values are ported verbatim from `app/globals.css` (HSL space-
/// separated) and converted to [Color] with CSS's exact `hsl()` algorithm.
/// `primary` is a *slot* whose actual value is supplied at runtime by the
/// per-gym `primaryColor` override — see [ThemeTokens.copyWithPrimary].
@immutable
class ThemeTokens {
  const ThemeTokens({
    required this.background,
    required this.foreground,
    required this.card,
    required this.popover,
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.accent,
    required this.destructive,
    required this.success,
    required this.warning,
    required this.border,
    required this.ring,
    required this.dock,
    required this.radius,
  });

  final Color background;
  final Color foreground;
  final TokenColor card;
  final TokenColor popover;
  final TokenColor primary;
  final TokenColor secondary;
  final TokenColor muted;
  final TokenColor accent;
  final TokenColor destructive;
  final TokenColor success;
  final TokenColor warning;
  final Color border;
  final Color ring;
  final TokenColor dock;

  /// App-wide corner radius (`--radius: 1.125rem` = 18px).
  final double radius;

  /// Returns a copy using [primary] (and its foreground, when supplied) —
  /// the mechanism that applies a per-gym `primaryColor` override while
  /// preserving the rest of the palette.
  ThemeTokens copyWithPrimary(Color primary, {Color? primaryForeground}) {
    return ThemeTokens(
      background: background,
      foreground: foreground,
      card: card,
      popover: popover,
      primary: TokenColor(primary, primaryForeground ?? this.primary.foreground),
      secondary: secondary,
      muted: muted,
      accent: accent,
      destructive: destructive,
      success: success,
      warning: warning,
      border: border,
      ring: ring,
      dock: dock,
      radius: radius,
    );
  }
}

/// Shared radius token. `--radius: 1.125rem` = 18px.
const double kAppRadius = 18.0;

/// Light palette — `:root` in `app/globals.css`.
const ThemeTokens lightTokens = ThemeTokens(
  background: Color(0xFFF8F5F1), // 34 33% 96%
  foreground: Color(0xFF101728), // 222 42% 11%
  card: TokenColor(Color(0xFFFFFFFF), Color(0xFF101728)), // 0 0% 100% / 222 42% 11%
  popover: TokenColor(Color(0xFFFFFFFF), Color(0xFF101728)),
  primary: TokenColor(Color(0xFFF55F2E), Color(0xFFFFFFFF)), // 15 91% 57%
  secondary: TokenColor(Color(0xFFF2E7DE), Color(0xFF763413)), // 28 45% 91% / 20 72% 27%
  muted: TokenColor(Color(0xFFEDE8E3), Color(0xFF606876)), // 30 22% 91% / 220 10% 42%
  accent: TokenColor(Color(0xFFDEEBED), Color(0xFF1D4249)), // 185 28% 90% / 190 44% 20%
  destructive: TokenColor(Color(0xFFE23936), Color(0xFFFFFFFF)), // 1 75% 55%
  success: TokenColor(Color(0xFF2A9D69), Color(0xFFFFFFFF)), // 153 58% 39%
  warning: TokenColor(Color(0xFFF6A313), Color(0xFF532E09)), // 38 93% 52% / 30 80% 18%
  border: Color(0xFFE5DDD7), // 27 22% 87%
  ring: Color(0xFFF55F2E), // 15 91% 57%
  dock: TokenColor(Color(0xFF12192B), Color(0xFFF5F1EA)), // 222 42% 12% / 35 35% 94%
  radius: kAppRadius,
);

/// Dark palette — `.dark` in `app/globals.css`.
const ThemeTokens darkTokens = ThemeTokens(
  background: Color(0xFF0E121B), // 222 32% 8%
  foreground: Color(0xFFEEF2F6), // 210 30% 95%
  card: TokenColor(Color(0xFF161B27), Color(0xFFEEF2F6)), // 222 27% 12%
  popover: TokenColor(Color(0xFF171C26), Color(0xFFEEF2F6)),
  primary: TokenColor(Color(0xFFF66B3C), Color(0xFFFFFFFF)), // 15 91% 60%
  secondary: TokenColor(Color(0xFF232A38), Color(0xFFEEF2F6)), // 222 23% 18%
  muted: TokenColor(Color(0xFF232834), Color(0xFF94A3B8)), // 222 20% 17% / 215 20% 65%
  accent: TokenColor(Color(0xFF243538), Color(0xFFEEF2F6)), // 190 22% 18%
  destructive: TokenColor(Color(0xFFCC2B28), Color(0xFFEEF2F6)), // 1 67% 48%
  success: TokenColor(Color(0xFF22C373), Color(0xFFFFFFFF)), // 150 70% 45%
  warning: TokenColor(Color(0xFFF7A922), Color(0xFF151B28)), // 38 93% 55% / 222 30% 12%
  border: Color(0xFF2A2F3C), // 222 18% 20%
  ring: Color(0xFFF66B3C), // 15 91% 60%
  dock: TokenColor(Color(0xFF19202E), Color(0xFFF5F1EA)), // 222 29% 14% / 35 35% 94%
  radius: kAppRadius,
);

/// Returns the token set for a given [brightness].
ThemeTokens tokensFor(Brightness brightness) =>
    brightness == Brightness.dark ? darkTokens : lightTokens;
