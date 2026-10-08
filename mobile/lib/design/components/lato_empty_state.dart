import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import 'lato_card.dart';

/// Centered empty-state block: tinted icon tile + title + body + optional CTA.
/// Used in Dashboard empty state, "No memberships expiring soon", etc.
class LatoEmptyState extends StatelessWidget {
  const LatoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LatoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: LatoSpacing.lg,
        vertical: LatoSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: LatoColors.surfaceRaisedDark,
              borderRadius: BorderRadius.circular(LatoRadius.md),
              border: Border.all(color: LatoColors.borderDark),
            ),
            child: Icon(icon, size: 24, color: LatoColors.textSecondaryDark),
          ),
          const SizedBox(height: LatoSpacing.lg),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: LatoSpacing.xs),
            Text(body!, style: text.bodySmall, textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: LatoSpacing.lg),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
