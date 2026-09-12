import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// Tab-root app bar reproducing the web `TopAppBar`: a translucent blurred
/// header with the brand row and a display title.
///
/// - Safe-area top padding + 0.75rem, `px-5 pb-3`.
/// - Brand row: dumbbell glyph in a `rounded-xl` primary chip (primary
///   background, primary-foreground icon, soft primary shadow) + "GYM MANAGER"
///   uppercase 10px extrabold with 0.2em tracking in primary color.
/// - Right side: [trailing] slot (GymPicker placeholder).
/// - Below: an `<h1>`-equivalent display title (Manrope ~32px extrabold,
///   tracking -0.045em, leading-none).
class TopAppBar extends StatelessWidget {
  const TopAppBar({super.key, required this.title, this.trailing});

  final String title;

  /// Replaces the GymPicker placeholder (Issues 14-18 wire a real picker).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final MediaQueryData media = MediaQuery.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(
          color: withOpacity(t.background, 0.80),
          child: Padding(
            padding: EdgeInsets.only(
              top: 12 + media.padding.top, // 0.75rem + safe-area top
              left: 20, // px-5
              right: 20,
              bottom: 12, // pb-3
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _BrandRow(tokens: t, trailing: trailing),
                const SizedBox(height: 8), // mt-2
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.045 * 32,
                    height: 1,
                    color: t.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.tokens, this.trailing});

  final ThemeTokens tokens;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // Brand mark: dumbbell in a rounded-xl primary chip.
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: tokens.primary.value,
            borderRadius: BorderRadius.circular(12), // rounded-xl
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: withOpacity(tokens.primary.value, 0.30),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.fitness_center,
            size: 14,
            color: tokens.primary.foreground,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Gym Manager',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2 * 10,
            color: tokens.primary.value,
            height: 1.2,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing! else const _GymPickerPlaceholder(),
      ],
    );
  }
}

/// A placeholder for the GymPicker until Issue 14 wires the real gym list +
/// bottom sheet. Renders the same pill shape as the web control.
class _GymPickerPlaceholder extends StatelessWidget {
  const _GymPickerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: t.card.value,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: withOpacity(t.border, 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.home_work_outlined, size: 14, color: t.muted.foreground),
          const SizedBox(width: 6),
          Text(
            'Choose gym',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.foreground),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 14, color: t.muted.foreground),
        ],
      ),
    );
  }
}
