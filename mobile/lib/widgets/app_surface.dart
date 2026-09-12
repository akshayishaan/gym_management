import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// Card container reproducing the `.app-surface` CSS utility.
///
/// Card background, a `1px` border at `hsl(var(--border) / 0.58)`, and a
/// double box-shadow:
///   `0 14px 34px -26px foreground@42%`, `0 2px 8px -5px foreground@18%`.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;

  /// Optional ink-well tap target wrapping the surface.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final Color border = withOpacity(t.border, 0.58);

    final Decoration decoration = BoxDecoration(
      color: color ?? t.card.value,
      borderRadius: borderRadius ?? BorderRadius.circular(t.radius),
      border: Border.all(color: border),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: withOpacity(t.foreground, 0.42),
          offset: const Offset(0, 14),
          blurRadius: 34,
          spreadRadius: -26,
        ),
        BoxShadow(
          color: withOpacity(t.foreground, 0.18),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: -5,
        ),
      ],
    );

    final Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      borderRadius:
          borderRadius ?? BorderRadius.circular(ext.tokens.radius),
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          customBorder:
              borderRadius == null
                  ? null
                  : RoundedRectangleBorder(borderRadius: borderRadius!),
          child: content,
        ),
      ),
    );
  }
}
