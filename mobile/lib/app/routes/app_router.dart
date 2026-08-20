import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/shell/screens/main_shell_screen.dart';
import '../../features/shell/screens/kaza_splash_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/map/screens/search_screen.dart';
import '../../features/saved/screens/saved_screen.dart';
import '../../features/publish/screens/publish_screen.dart';
import '../../features/financing/screens/financing_screen.dart';
import '../../features/financing/screens/financing_requests_screen.dart';
import '../../features/saved/screens/compare_tab_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/my_listings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// GoRouter configuration for Kaza — KAZA Master Design 5-Tab Shell
/// Tabs: Mapa, Buscar, Guardados, Comparar, Perfil
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── SPLASH SCREEN ────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      builder: (context, state) => const KazaSplashScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: MAPA
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
          ],
        ),

        // Tab 1: BUSCAR
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),

        // Tab 2: COMPARAR
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/compare',
              builder: (context, state) => const CompareTabScreen(),
            ),
          ],
        ),

        // Tab 4: PERFIL
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/my-listings',
      builder: (context, state) => const MyListingsScreen(),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) => const SavedScreen(),
    ),
    GoRoute(
      path: '/publish',
      builder: (context, state) => const PublishScreen(),
    ),
    GoRoute(
      path: '/financing',
      builder: (context, state) => const FinancingScreen(),
    ),
    GoRoute(
      path: '/financing-requests',
      builder: (context, state) => const FinancingRequestsScreen(),
    ),
  ],
);
