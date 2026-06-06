import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_shell.dart';
import '../../features/home/tabs/library_page.dart';
import '../../features/home/tabs/me_page.dart';
import '../../features/home/tabs/today_page.dart';
import '../../features/onboarding/onboarding_controller.dart';
import '../../features/onboarding/onboarding_flow.dart';
import '../../features/showcase_screen.dart';
import 'routes.dart';

/// App router. Onboarding gate via top-level redirect; main app is a
/// 3-tab indexed-stack shell (Today / Library / Me).
final routerProvider = Provider<GoRouter>((ref) {
  // read (not watch): pass the notifier as refreshListenable so the router is
  // built once and refreshed in place when onboarding completes.
  final onboarding = ref.read(onboardingControllerProvider);

  return GoRouter(
    initialLocation: Routes.today,
    refreshListenable: onboarding,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == Routes.showcase) return null; // dev route, always reachable

      final done = onboarding.complete;
      final atOnboarding = loc == Routes.onboarding;

      if (!done && !atOnboarding) return Routes.onboarding;
      if (done && atOnboarding) return Routes.today;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingFlow(),
      ),
      GoRoute(
        path: Routes.showcase,
        builder: (context, state) => const ShowcaseScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                builder: (context, state) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.library,
                builder: (context, state) => const LibraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.me,
                builder: (context, state) => const MePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
