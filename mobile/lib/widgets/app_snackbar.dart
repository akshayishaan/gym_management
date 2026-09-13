import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Shows a themed, floating [SnackBar] with [message].
///
/// Success/info uses the `dock` surface; errors use `destructive`. Text color
/// is the paired foreground token so it stays legible in both light and dark.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
  final ThemeTokens t = ext.tokens;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? t.destructive.foreground : t.dock.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? t.destructive.value : t.dock.value,
      ),
    );
}
