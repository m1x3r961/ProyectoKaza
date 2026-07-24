import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/shell/screens/main_shell_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/saved/screens/saved_screen.dart';
import '../../features/publish/screens/publish_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// GoRouter configuration for Kaza 5-Tab Stateful Navigation Shell
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/map',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: MAPA
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
          ],
        ),

        // Tab 2: GUARDADOS
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/saved',
              builder: (context, state) => const SavedScreen(),
            ),
          ],
        ),

        // Tab 3: + PUBLICAR
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/publish',
              builder: (context, state) => const PublishScreen(),
            ),
          ],
        ),

        // Tab 4: MENSAJES
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/messages',
              builder: (context, state) => const MessagesScreen(),
            ),
          ],
        ),

        // Tab 5: PERFIL
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
  ],
);
