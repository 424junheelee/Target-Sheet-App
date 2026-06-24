import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_provider.dart';
import 'screens/auth/first_run_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/menu/menu_screen.dart';
import 'screens/options/options_screen.dart';
import 'screens/scorecard_list/scorecard_list_screen.dart';
import 'screens/select/select_screen.dart';
import 'screens/shoot/shoot_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    final firstRunDone = await getFirstRunDone();
    if (!firstRunDone) {
      if (!state.matchedLocation.startsWith('/auth/first-run')) {
        return '/auth/first-run';
      }
    }
    return null;
  },
  routes: [
    // ── Auth routes ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/auth/first-run',
      builder: (context, state) => FirstRunScreen(
        onSignIn:  () => context.go('/auth/sign-in'),
        onOffline: () => context.go('/'),
      ),
    ),
    GoRoute(
      path: '/auth/sign-in',
      builder: (context, state) => SignInScreen(
        onSignedIn:      () => context.go('/'),
        onCreateAccount: () => context.go('/auth/sign-up'),
      ),
    ),
    GoRoute(
      path: '/auth/sign-up',
      builder: (context, state) => SignUpScreen(
        onSignedUp: () => context.go('/'),
        onSignIn:   () => context.go('/auth/sign-in'),
      ),
    ),

    // ── App routes ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => MenuScreen(
        onNewString:  () => context.push('/select'),
        onScorecards: () => context.push('/scorecards'),
        onOptions:    () => context.push('/options'),
        onShoot:      () => context.push('/shoot'),
      ),
    ),
    GoRoute(
      path: '/select',
      builder: (context, state) => SelectScreen(
        onSelected: (_) => context.push('/shoot'),
      ),
    ),
    GoRoute(
      path: '/shoot',
      builder: (context, state) => const ShootScreen(),
    ),
    GoRoute(
      path: '/scorecards',
      builder: (context, state) => const ScorecardListScreen(),
    ),
    GoRoute(
      path: '/options',
      builder: (context, state) => const OptionsScreen(),
    ),
  ],
);
