import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Themed floating action button mirroring the web `Fab` (60px, rounded
/// ~21.6px, `bg-primary text-primary-foreground`). Position it in screens via
/// `Stack`/`Positioned`.
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.onPressed, this.icon = Icons.add});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: t.primary.value,
        foregroundColor: t.primary.foreground,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21.6), // 1.35rem
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
