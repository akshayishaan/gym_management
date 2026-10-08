import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/components/lato_card.dart';
import '../../../design/spacing.dart';
import '../application/auth_controller.dart';

/// Welcome screen, shown on the first launch after install and right after
/// signing out: the splash artwork plus a "Get started" CTA that continues to
/// the login form. The router decides when it appears (`showWelcome`).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Artwork is near the phone's aspect ratio; anchoring to the top
          // keeps the logo and face intact on taller or wider screens.
          Image.asset(
            'assets/splash1.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true,
          ),
          // Soft fade to black so the CTA stays readable over the artwork.
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                LatoSpacing.xl,
                LatoSpacing.xxl,
                LatoSpacing.xl,
                LatoSpacing.xxl,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: LatoPrimaryButton(
                  label: 'Get started',
                  onPressed: () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .dismissWelcome();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
