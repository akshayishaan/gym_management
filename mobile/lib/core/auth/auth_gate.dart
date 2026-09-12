import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../../data/gym_providers.dart';
import '../../screens/login_screen.dart';
import '../../theme/theme.dart';
import '../../widgets/app_canvas.dart';
import '../../widgets/app_section_label.dart';
import '../../widgets/app_surface.dart';
import '../api/api_exception.dart';
import '../settings/gym_settings_controller.dart';
import '../settings/gym_settings_state.dart';
import '../settings/theme_controller.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

/// The top-level routing gate: routes on [AuthStatus].
///
/// - `unknown` (session restore in flight) → centered spinner.
/// - `unauthenticated` → [LoginScreen].
/// - `authenticated` → [GymGate], which resolves the gym list before revealing
///   the shell.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  /// The authenticated shell (e.g. the tab-root `AppShell`).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authControllerProvider);

    switch (auth.status) {
      case AuthStatus.unknown:
        return const _LoadingScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return GymGate(child: child);
    }
  }
}

/// Resolves the authenticated user's gym list and gates the shell on it.
///
/// While the list loads it shows a spinner; on error an error surface with a
/// retry; on an empty list an empty-state with a sign-out action. Once data
/// resolves it reconciles the gym selection (exactly once) and applies the
/// resolved gym's primary color to the theme, then reveals [child].
class GymGate extends ConsumerStatefulWidget {
  const GymGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GymGate> createState() => _GymGateState();
}

class _GymGateState extends ConsumerState<GymGate> {
  bool _reconciled = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<GymResponse>> gyms = ref.watch(gymsProvider);

    // Apply the resolved gym primary color to the theme whenever the selection
    // (and therefore its `primaryColor`) changes.
    ref.listen<GymSettingsState>(
      gymSettingsControllerProvider,
      (GymSettingsState? previous, GymSettingsState next) {
        if (previous?.selectedGymId == next.selectedGymId &&
            previous?.primaryColor == next.primaryColor) {
          return;
        }
        ref
            .read(themeControllerProvider.notifier)
            .setGym(primaryColor: next.primaryColor);
      },
    );

    // Reconcile the selection exactly once, once the gym list first resolves.
    ref.listen<AsyncValue<List<GymResponse>>>(
      gymsProvider,
      (AsyncValue<List<GymResponse>>? previous,
          AsyncValue<List<GymResponse>> next) {
        _reconcileOnce(next);
      },
    );

    return gyms.when(
      loading: () => const _LoadingScreen(),
      error: (Object error, StackTrace stackTrace) => _ErrorScreen(
        error: error,
        onRetry: () => ref.invalidate(gymsProvider),
      ),
      data: (List<GymResponse> data) {
        if (data.isEmpty) {
          return const _EmptyGymsScreen();
        }
        return widget.child;
      },
    );
  }

  void _reconcileOnce(AsyncValue<List<GymResponse>> gyms) {
    if (_reconciled) return;

    final List<GymResponse>? data = gyms.valueOrNull;
    if (data == null) return; // still loading or errored — try again on data.

    _reconciled = true;
    unawaited(_reconcileGyms(data));
  }

  /// Restores the persisted selection and resolves it against [data] once the
  /// gym list first resolves. Fire-and-forget on purpose (it must not block the
  /// shell's first render), but guarded so a failure never becomes an unhandled
  /// async exception.
  Future<void> _reconcileGyms(List<GymResponse> data) async {
    final GymSettingsController controller = ref.read(
      gymSettingsControllerProvider.notifier,
    );
    try {
      await controller.initialize();
      await controller.reconcileGyms(data);
    } catch (error, stackTrace) {
      // Best-effort: selection reconciliation failing must not crash the app.
      // Surface it in debug builds so it's visible during development.
      debugPrint('Gym reconciliation failed: $error\n$stackTrace');
    }
  }
}

/// Full-bleed centered spinner for the loading/restore states.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = _tokens(context);
    return AppCanvas(
      child: Center(
        child: CircularProgressIndicator(color: t.primary.value),
      ),
    );
  }
}

/// Error surface shown when the gym list fails to load.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = _tokens(context);
    final String message = error is ApiException
        ? (error as ApiException).userMessage
        : error.toString();

    return AppCanvas(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppSectionLabel('Something went wrong'),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: t.muted.foreground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state for an authenticated user with no gyms yet.
class _EmptyGymsScreen extends ConsumerWidget {
  const _EmptyGymsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeTokens t = _tokens(context);

    return AppCanvas(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppSectionLabel('No gyms yet'),
                    const SizedBox(height: 8),
                    Text(
                      'Your account isn\u2019t linked to any gyms. Ask an '
                      'administrator to add you, or sign in with a different '
                      'account.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: t.muted.foreground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                        child: const Text('Sign out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

ThemeTokens _tokens(BuildContext context) =>
    Theme.of(context).extension<AppThemeTokens>()!.tokens;
