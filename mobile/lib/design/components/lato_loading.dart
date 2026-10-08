import 'package:flutter/material.dart';

import '../colors.dart';

/// Centered loading spinner with optional caption. Replaces the many ad-hoc
/// `Center(child: CircularProgressIndicator())` blocks spread across feature
/// screens so the spinner style stays consistent.
class LatoLoading extends StatelessWidget {
  const LatoLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.5,
            color: LatoColors.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: LatoColors.textSecondaryDark,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
