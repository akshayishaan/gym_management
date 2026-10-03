import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/components/lato_card.dart';
import '../application/auth_controller.dart';

/// Figma "01 login" — RepiX brand splash with the "Get started" CTA.
///
/// Shows the RepiX logotype over a black background with a hero illustration
/// and the tagline. Tapping "Get started" routes to the real login form.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch the auth state. As soon as rehydration says "already signed in",
    // the router's redirect kicks us to /home — but we also proactively push
    // from here so the brand page doesn't flash on cold start.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.stage == AuthStage.authenticated) {
        if (context.mounted) context.go('/home');
      } else if (next.stage == AuthStage.unauthenticated) {
        if (context.mounted) context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo + tagline
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
              const SizedBox(height: 8),
              Text(
                'TRACK  ◆  IMPROVE  ◆  GROW',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              // CTA
              LatoPrimaryButton(
                label: 'Get started',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}