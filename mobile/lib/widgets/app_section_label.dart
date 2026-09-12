import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Uppercase section label reproducing `.app-section-label`:
/// 11px, weight 700, `muted-foreground` color, `0.13em` letter-spacing.
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;

  /// Convenience for overriding default [TextAlign.start] when the label
  /// sits in a constrained or centered row.
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.13 * 11, // 0.13em ≈ 1.43px at 11px.
        color: t.muted.foreground,
      ),
    );
  }
}
