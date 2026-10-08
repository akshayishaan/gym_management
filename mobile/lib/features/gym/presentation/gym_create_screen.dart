import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/spacing.dart';
import '../../auth/application/auth_controller.dart';
import 'gym_form_sheet.dart';

/// First-run gym gate at `/gym/new`.
///
/// A signed-in account with no gym cannot reach the dashboard: the router
/// forces this screen until a gym exists (fresh signup, or after deleting the
/// last gym). It opens the same Add Gym bottom sheet the My Gyms screen uses,
/// so the inputs stay identical in both places. Creating a gym flips the auth
/// stage to authenticated and the router moves on to `/home`. "Sign out" is the
/// only escape for someone who signed up with the wrong account.
class GymCreateScreen extends ConsumerWidget {
  const GymCreateScreen({super.key});

  Future<void> _addGym(BuildContext context) async {
    // The sheet's create path adds the gym to the account, selects it, and
    // flips the auth stage to authenticated; the router redirect then takes
    // the user to /home. Nothing to do with the result here.
    await showLatoFormSheet<GymFormResult>(
      context: context,
      builder: (_) => const GymFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: LatoColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LatoSpacing.xl,
            LatoSpacing.xxl,
            LatoSpacing.xl,
            LatoSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Brand wordmark, matching the splash screen.
              Text(
                'RepiX',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: LatoSpacing.xxl),
              Text(
                'Set up your first gym',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: LatoSpacing.sm),
              Text(
                'Add a gym to start managing members, plans and payments.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              LatoPrimaryButton(
                label: 'Add your gym',
                onPressed: () => _addGym(context),
              ),
              const SizedBox(height: LatoSpacing.sm),
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
