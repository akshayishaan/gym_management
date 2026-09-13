import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// Full-bleed canvas reproducing the `.app-canvas` CSS utility: a stack of
/// two radial gradients over the background color.
///
/// ```
/// radial-gradient(circle at 92% 2%,   primary @ 11%, transparent 25rem),
/// radial-gradient(circle at -10% 45%, accent  @ 55%, transparent 22rem),
/// hsl(var(--background))
/// ```
///
/// In CSS the first gradient is the *topmost* layer, so paint order is:
/// background color → accent glow → primary glow → content. [Stack] paints its
/// children bottom-to-top, so we list them in exactly that order. Gradient
/// centers reuse the CSS percentage coordinates (converted to Flutter's
/// `Alignment` -1..1 space); radii are expressed in Flutter's convention
/// (relative to the shortest viewport side) and tuned so the ~25rem/22rem
/// halos read identically on a phone-sized canvas.
class AppCanvas extends StatelessWidget {
  const AppCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    // `circle at 92% 2%`  → center (92%, 2%).
    // `circle at -10% 45%` → center (-10%, 45%).
    // Alignment.x ∈ [-1..1] maps left→right as -100%..100%.
    const Alignment primaryCenter = Alignment(0.84, -0.96);
    const Alignment accentCenter = Alignment(-1.1, -0.1);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Layer 1 (bottom) — flat background.
          ColoredBox(color: t.background),
          // Layer 2 — accent wash from the left edge.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: accentCenter,
                radius: 1.4,
                colors: <Color>[
                  withOpacity(t.accent.value, 0.55),
                  withOpacity(t.accent.value, 0),
                ],
              ),
            ),
          ),
          // Layer 3 (top glow) — primary halo in the top-right.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: primaryCenter,
                radius: 1.6,
                colors: <Color>[
                  withOpacity(t.primary.value, 0.11),
                  withOpacity(t.primary.value, 0),
                ],
              ),
            ),
          ),
          // Layer 4 — content.
          child,
        ],
      ),
    );
  }
}
