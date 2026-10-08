import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../colors.dart';
import '../spacing.dart';

/// "Showing 20 of 142" with a Load more button, shown under the last row of a
/// paged list. Also covers the in-flight and failed-to-load states.
class LatoLoadMoreFooter extends StatelessWidget {
  const LatoLoadMoreFooter({
    super.key,
    required this.shown,
    required this.total,
    required this.loading,
    required this.failed,
    required this.onLoadMore,
    required this.onRetry,
  });

  final int shown;
  final int total;
  final bool loading;
  final bool failed;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget action;
    if (loading) {
      action = const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: LatoColors.primary,
            ),
          ),
        ),
      );
    } else if (failed) {
      action = OutlinedButton(
        onPressed: onRetry,
        child: const Text('Could not load more. Retry'),
      );
    } else {
      action = OutlinedButton(
        onPressed: onLoadMore,
        child: const Text('Load more'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: LatoSpacing.xs),
      child: Column(
        children: [
          Text(
            'Showing $shown of ${NumberFormat.decimalPattern().format(total)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: LatoSpacing.md),
          action,
        ],
      ),
    );
  }
}
