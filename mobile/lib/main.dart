import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'design/theme.dart';
import 'features/settings/application/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: RepiXApp()));
}

/// Root app widget. Phase 0/2 ships:
///   * Lato-themed Material 3 app (light + dark, defaults to dark)
///   * GoRouter wired to AuthController — login ↔ home transitions
///     are driven by auth state, not imperative navigation calls.
class RepiXApp extends ConsumerWidget {
  const RepiXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'RepiX',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(materialThemeModeProvider),
      theme: LatoTheme.light(),
      darkTheme: LatoTheme.dark(),
      routerConfig: router,
    );
  }
}