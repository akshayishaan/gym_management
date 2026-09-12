import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// Header for drill-in / full-screen pages (member detail, add/edit forms),
/// reproducing the web `StackHeader`:
///
/// - Top bar with bottom border `border @50%`, blurred translucent background,
///   safe-area top + 0.5rem, `px-3 pb-2`.
/// - 44x44 back button: rounded-card (radius ~16, card background, soft
///   shadow) with a `ChevronLeft` glyph (stroke 2.5).
/// - Title in Manrope (~28px, bold), optional [actions] slot.
/// - [onBack] falls back to `Navigator.pop` when unset.
class StackHeader extends StatelessWidget {
  const StackHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

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
          color: withOpacity(t.background, 0.85),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: withOpacity(t.border, 0.50),
                ),
              ),
            ),
            padding: EdgeInsets.only(
              top: 8 + media.padding.top, // 0.5rem + safe-area top
              left: 12, // px-3
              right: 12,
              bottom: 8, // pb-2
            ),
            child: Row(
              children: <Widget>[
                _BackButton(tokens: t, onBack: onBack),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02,
                      color: t.foreground,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.tokens, this.onBack});

  final ThemeTokens tokens;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tokens.card.value,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: withOpacity(tokens.foreground, 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.chevron_left,
            size: 20,
            color: tokens.foreground,
          ),
        ),
      ),
    );
  }
}
