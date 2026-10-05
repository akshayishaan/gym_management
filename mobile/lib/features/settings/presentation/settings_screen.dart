// Phase 9 Track A placeholder. Track B will replace this with the real
// settings surface (theme toggle, staff profile, sign-out, etc.). It just
// needs to resolve the `/settings` route so the More menu doesn't crash.
import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/spacing.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LatoColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(LatoSpacing.xxl),
          child: Text(
            'Settings — coming soon',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}