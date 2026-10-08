import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

/// How long the artwork stays up on launch, even if auth rehydrates sooner.
const kSplashMinDuration = Duration(milliseconds: 1500);

/// RepiX splash: the full-bleed brand artwork (`splash1.png`, which already
/// carries the logotype and tagline) and nothing else. It has no navigation
/// of its own: once [kSplashMinDuration] has passed it marks itself done and
/// the router sends the user to home, gym creation, welcome or login.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(kSplashMinDuration, () {
      if (mounted) ref.read(splashDoneProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        // Artwork is near the phone's aspect ratio; anchoring to the top
        // keeps the logo and face intact on taller or wider screens.
        child: Image.asset(
          'assets/splash1.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
