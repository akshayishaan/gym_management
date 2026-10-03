import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

enum LatoChipTone { success, warning, error, neutral, primary }

/// A small status pill used for "ACTIVE", "X days left", "Voided" etc.
class LatoStatusChip extends StatelessWidget {
  const LatoStatusChip({
    super.key,
    required this.label,
    this.tone = LatoChipTone.neutral,
    this.icon,
  });

  final String label;
  final LatoChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _resolve(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LatoSpacing.md,
        vertical: LatoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: LatoRadius.chip,
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: colors.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  _ChipColors _resolve(LatoChipTone tone) {
    switch (tone) {
      case LatoChipTone.success:
        return const _ChipColors(
          bg: Color(0x3300C853),
          fg: LatoColors.success,
          border: LatoColors.success,
        );
      case LatoChipTone.warning:
        return const _ChipColors(
          bg: Color(0x33FB923C),
          fg: LatoColors.warning,
          border: LatoColors.warning,
        );
      case LatoChipTone.error:
        return const _ChipColors(
          bg: Color(0x33EF4444),
          fg: LatoColors.error,
          border: LatoColors.error,
        );
      case LatoChipTone.primary:
        return const _ChipColors(
          bg: Color(0x33C5F23F),
          fg: LatoColors.primary,
          border: LatoColors.primary,
        );
      case LatoChipTone.neutral:
        return const _ChipColors(
          bg: Color(0x1AFFFFFF),
          fg: LatoColors.textSecondaryDark,
          border: LatoColors.borderDark,
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({required this.bg, required this.fg, required this.border});
  final Color bg;
  final Color fg;
  final Color border;
}
