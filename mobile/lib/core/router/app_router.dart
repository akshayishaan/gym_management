import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
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

      // If we're already at /splash and we now know the user is authed,
      // bounce them to the home shell.
      if (loc == '/splash' && auth.stage == AuthStage.authenticated) {
        return '/home';
      }

      // Unauthenticated users can only see splash / login / signup.
      if (auth.stage == AuthStage.unauthenticated) {
        if (loc == '/splash' || loc == '/login' || loc == '/signup') {
          return null;
        }
        return '/splash';
      }

      // Authenticated users shouldn't see the splash or login screens.
      if (auth.stage == AuthStage.authenticated) {
        if (loc == '/splash' || loc == '/login' || loc == '/signup') {
          return '/home';
        }
      }
      return null;
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
