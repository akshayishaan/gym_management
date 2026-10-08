import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// A filled dark card with a subtle 1px border. Matches the surface cards
/// shown throughout the Figma (Monthly Revenue, Expiring Soon rows, etc.).
class LatoCard extends StatelessWidget {
  const LatoCard({
    super.key,
    required this.child,
    this.padding = LatoSpacing.cardAll,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = color ?? theme.colorScheme.surface;
    final border = borderColor ?? theme.colorScheme.outline;

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: LatoRadius.card,
        border: Border.all(color: border, width: 1),
      ),
      child: child,
    );

    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: LatoRadius.card,
        child: container,
      ),
    );
  }
}

/// A solid primary (lime) CTA button. Wraps [FilledButton] but enforces the
/// RepiX button height and shape so the visual matches the Figma exactly.
class LatoPrimaryButton extends StatelessWidget {
  const LatoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: disabled ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(LatoSizes.button),
          backgroundColor: LatoColors.primary,
          foregroundColor: LatoColors.bgDark,
          disabledBackgroundColor: LatoColors.primary.withValues(alpha: 0.4),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: LatoColors.bgDark,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
