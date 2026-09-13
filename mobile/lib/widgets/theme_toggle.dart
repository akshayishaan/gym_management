import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/theme_controller.dart';
import '../theme/theme.dart';

/// A dark-mode toggle row: label + icon + a switch that flips the app's
/// explicit brightness (or clears the override back to system).
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isDark ? 'Dark theme' : 'Light theme',
                style: TextStyle(fontSize: 12, color: t.muted.foreground),
              ),
            ],
          ),
        ),
        Icon(
          isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
          size: 20,
          color: isDark ? t.warning.value : t.primary.value,
        ),
        const SizedBox(width: 8),
        Switch(
          value: isDark,
          activeThumbColor: t.primary.foreground,
          activeTrackColor: t.primary.value,
          onChanged: (_) => ref
              .read(themeControllerProvider.notifier)
              .setBrightness(isDark ? Brightness.light : Brightness.dark),
        ),
      ],
    );
  }
}
