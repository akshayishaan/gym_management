import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/gym/presentation/gym_create_screen.dart';
import '../../features/gym/presentation/gyms_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/members/presentation/member_detail_screen.dart';
import '../../features/members/presentation/members_list_screen.dart';
import '../../features/payments/presentation/payment_invoice_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/plans/presentation/plan_detail_screen.dart';
import '../../features/plans/presentation/plans_list_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/more/presentation/root_shell.dart';
import '../../features/activity/presentation/activity_log_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';

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
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      if (!rehydrated) {
        // Don't redirect during the very first frame; let the splash show
        // until the controller finishes rehydrating tokens.
        return null;
      }
      // Hold the splash for its minimum duration; SplashScreen flips this.
      if (loc == '/splash' && !ref.read(splashDoneProvider)) return null;

      // Stage-driven routing: each stage owns a set of allowed paths.
      const authOnlyPaths = {'/splash', '/welcome', '/login', '/signup'};
      const gymGatePaths = {'/splash', '/gym/new'};

      switch (auth.stage) {
        case AuthStage.unknown:
          // Rehydration still in progress; only splash makes sense.
          return loc == '/splash' ? null : '/splash';

        case AuthStage.unauthenticated:
          // Welcome (first launch / after logout) comes before login;
          // otherwise a cold start goes splash -> login.
          final entry = auth.showWelcome ? '/welcome' : '/login';
          if (loc == '/login' || loc == '/signup') return null;
          if (loc == '/welcome') return auth.showWelcome ? null : '/login';
          return entry;

        case AuthStage.needsGymCreation:
          // Allow only splash and gym creation. We deliberately do NOT
          // allow /login or /signup once the user has a valid session —
          // even one without gyms — otherwise a state change to
          // needsGymCreation leaves them stuck on the login screen.
          if (gymGatePaths.contains(loc)) return null;
          return '/gym/new';

        case AuthStage.authenticated:
          // Logged-in users shouldn't sit on splash/login/signup or the
          // gym-creation gate.
          if (authOnlyPaths.contains(loc) || loc == '/gym/new') {
            return '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/gym/new', builder: (_, _) => const GymCreateScreen()),
      ShellRoute(
        builder: (context, state, child) => RootShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const DashboardScreen()),
          GoRoute(
            path: '/members',
            builder: (_, _) => const MembersListScreen(),
          ),
          // /members/:id is intentionally inside the ShellRoute so the
          // bottom nav stays visible (matches the Figma detail design).
          GoRoute(
            path: '/members/:id',
            builder: (_, state) =>
                MemberDetailScreen(id: state.pathParameters['id']!),
          ),
          // The "add member" entry point is NOT a separate route — the
          // list screen opens it via showModalBottomSheet (full-height
          // form sheet from Figma). Keeping it modal avoids another nav
          // stack push and matches the design.
          GoRoute(path: '/payments', builder: (_, _) => const PaymentsScreen()),
          // Phase 9 renamed the route handler from `OperationsScreen`
          // (a Phase 6 stub that just hosted the plans list) to the
          // `MoreScreen` menu. The bottom-nav "Operations" tab still
          // opens this route; Plans, Reports, Activity, and My Gyms are
          // now listed as navigation rows inside the menu rather than
          // as sibling top-level routes.
          GoRoute(path: '/operations', builder: (_, _) => const MoreScreen()),
          // /payments/:id — invoice detail. Stays inside the ShellRoute
          // so the bottom nav stays visible. Track B's screen replaces
          // the stub `PaymentInvoiceScreen` wholesale.
          GoRoute(
            path: '/payments/:id',
            builder: (_, state) =>
                PaymentInvoiceScreen(id: state.pathParameters['id']!),
          ),
          // /plans — Membership Plans list. Was previously unreachable:
          // the More menu's "Plans" row pointed at '/operations' (a
          // self-loop back to the menu it was opened from) because this
          // route didn't exist yet. The screen itself (PlansListScreen)
          // has existed and been backend-wired since Phase 6.
          GoRoute(path: '/plans', builder: (_, _) => const PlansListScreen()),
          // /plans/:id — tapping a plan card opens this detail screen.
          // Stays inside the ShellRoute so the bottom nav remains
          // visible (matches the Figma detail view).
          GoRoute(
            path: '/plans/:id',
            builder: (_, state) =>
                PlanDetailScreen(id: state.pathParameters['id']!),
          ),
          // /activity — Phase 8 Track B fills this in. Inside the
          // ShellRoute so the bottom nav stays visible (matches the
          // Figma detail-style activity feed).
          GoRoute(
            path: '/activity',
            builder: (_, _) => const ActivityLogScreen(),
          ),
          // /reports — Phase 8 Track C fills this in. Inside the
          // ShellRoute so the bottom nav stays visible.
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          // /gyms — My Gyms: switch, add, edit and delete gyms. Inside the
          // ShellRoute so the bottom nav stays visible.
          GoRoute(path: '/gyms', builder: (_, _) => const GymsScreen()),
        ],
      ),
    ],
  );
});

/// Adapts the Riverpod auth state into a [Listenable] that GoRouter can
/// subscribe to. The router re-runs its `redirect` whenever this notifies.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(authControllerProvider, (prev, next) {
      notifyListeners();
    });
    _splashSub = _ref.listen<bool>(splashDoneProvider, (prev, next) {
      notifyListeners();
    });
  }
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;
  late final ProviderSubscription<bool> _splashSub;

  @override
  void dispose() {
    _sub.close();
    _splashSub.close();
    super.dispose();
  }
}
