import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';

/// Placeholder for the Payments tab — Issue 16 wires the month filter, the
/// payments list and client-side invoice PDF.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext =
        Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppScreen(
        children: <Widget>[
          const AppSectionLabel('Payments'),
          const SizedBox(height: 12),
          AppSurface(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Recorded payments, void/refund actions and invoice PDF '
              'generation arrive with Issue 16.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: t.muted.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
