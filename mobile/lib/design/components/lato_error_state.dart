import 'package:flutter/material.dart';

import '../colors.dart';
import 'lato_card.dart';

/// Centered error state with cloud-off icon, message, and an optional
/// retry button. Used as the `error:` branch of an `AsyncValue.when` so
/// every feature screen renders failures the same way.
class LatoErrorState extends StatelessWidget {
  const LatoErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: LatoColors.textSecondaryDark,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LatoColors.textPrimaryDark,
                fontSize: 14,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: LatoPrimaryButton(
                  label: retryLabel,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
