import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// The primary "create" action of a list screen: a lime round FAB with a plus
/// icon at the bottom right, above the bottom navigation bar (Material 3
/// placement). [label] is the tooltip and the screen-reader name.
///
/// Lists under it should pad their bottom by [LatoSpacing.fabClearance] so the
/// last card is never covered.
class LatoFab extends StatelessWidget {
  const LatoFab({super.key, required this.label, required this.onPressed});

  /// Short noun phrase, e.g. `New Member`.
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Scaffold's end-float margin is 16; the page margin is 20.
      padding: const EdgeInsets.only(
        right: LatoSpacing.xs,
        bottom: LatoSpacing.xs,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: label,
        backgroundColor: LatoColors.primary,
        foregroundColor: LatoColors.bgDark,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: LatoRadius.card),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
