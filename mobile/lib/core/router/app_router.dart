import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/gym/presentation/gym_create_screen.dart';
import '../../features/gym/presentation/gym_picker_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/members/presentation/members_list_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/more/presentation/operations_screen.dart';
import '../../features/more/presentation/root_shell.dart';

/// Single source of truth for navigation. Phases 3+ add their own routes
/// (gym picker, member detail, etc.) on top of this.
final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever auth state changes, so a successful login
  // routes the user out of /login even when they're already on that screen.
  final notifier = AuthRouterRefresh(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final rehydrated = ref.read(authRehydratedProvider);
      if (!rehydrated) {
        // Don't redirect during the very first frame; let the splash show
        // until the controller finishes rehydrating tokens.
        return null;
      }
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Stage-driven routing: each stage owns a set of allowed paths.
      const authOnlyPaths = {'/splash', '/login', '/signup'};
      const gymGatePaths = {'/splash', '/login', '/signup', '/gym/new'};
      const pickerPaths = {
        '/splash',
        '/login',
        '/signup',
        '/gym/new',
        '/gym/picker',
      };

      switch (auth.stage) {
        case AuthStage.unknown:
          // Rehydration still in progress; only splash makes sense.
          return loc == '/splash' ? null : '/splash';

        case AuthStage.unauthenticated:
          if (authOnlyPaths.contains(loc)) return null;
          return '/splash';

        case AuthStage.needsGymCreation:
          if (gymGatePaths.contains(loc)) return null;
          return '/gym/new';

        case AuthStage.needsGymSelection:
          if (pickerPaths.contains(loc)) return null;
          return '/gym/picker';

        case AuthStage.authenticated:
          // Logged-in users shouldn't sit on splash/login/signup.
          if (authOnlyPaths.contains(loc) ||
              loc == '/gym/new' ||
              loc == '/gym/picker') {
            return '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const SignupScreen(),
      ),
      GoRoute(
        path: '/gym/new',
        builder: (_, _) => const GymCreateScreen(),
      ),
      GoRoute(
        path: '/gym/picker',
        builder: (_, _) => const GymPickerScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => RootShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/members',
            builder: (_, _) => const MembersListScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (_, _) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/operations',
            builder: (_, _) => const OperationsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Adapts the Riverpod auth state into a [Listenable] that GoRouter can
/// subscribe to. The router re-runs its `redirect` whenever this notifies.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
