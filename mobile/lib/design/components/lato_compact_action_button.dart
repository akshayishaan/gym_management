import 'package:flutter/material.dart';

import '../spacing.dart';

/// Outlined action used inside cards: 36dp tall to keep cards compact, with a
/// 48dp tap area (padded tap target).
class LatoCompactActionButton extends StatelessWidget {
  const LatoCompactActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: LatoRadius.button),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}
