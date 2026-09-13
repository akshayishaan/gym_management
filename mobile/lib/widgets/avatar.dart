import 'package:flutter/material.dart';

import '../data/formatters.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';

/// Circular initials avatar mirroring the web's `Avatar`/`AvatarFallback`.
///
/// When no [background] is supplied it renders the web's primary→warning
/// gradient fallback (`from-primary/20 to-warning/20`) with a
/// `ring-4 ring-primary/5` ring; with a solid [background] the ring is kept
/// but the fill is flat and initials use `primary.foreground`.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.size = 48,
    this.background,
  });

  final String name;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    final Decoration fill = background != null
        ? BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(size / 2),
          )
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                withOpacity(t.primary.value, 0.20),
                withOpacity(t.warning.value, 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(size / 2),
          );

    final Color initialsColor =
        background != null ? t.primary.foreground : t.foreground;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4), // 4px ring
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: withOpacity(t.primary.value, 0.05), width: 4),
      ),
      child: DecoratedBox(
        decoration: fill,
        child: Center(
          child: Text(
            getInitials(name),
            style: TextStyle(
              color: initialsColor,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
