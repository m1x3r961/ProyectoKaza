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
import '../../features/ai_assistant/screens/ai_hub_screen.dart';
import '../../features/ai_assistant/screens/ai_chat_screen.dart';
import '../../features/saved/screens/compare_tab_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/my_listings_screen.dart';
import '../../features/organizations/screens/organizations_hub_screen.dart';
import '../../features/kaza_trust/screens/kaza_trust_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/subscription_plans_screen.dart';
import '../../features/profile/screens/basic_stats_screen.dart';
import '../../features/crm/screens/pro_dashboard_screen.dart';
import '../../features/crm/screens/crm_contacts_screen.dart';
import '../../features/crm/screens/crm_opportunities_screen.dart';
import '../../features/organizations/screens/business_dashboard_screen.dart';
import '../../features/organizations/screens/org_members_screen.dart';
import '../../features/organizations/screens/org_properties_screen.dart';
import '../../features/organizations/screens/org_opportunities_screen.dart';
import '../../features/properties/screens/tour_360_screen.dart';

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

        // Tab 1: GUARDADOS
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/saved-tab',
              builder: (context, state) => const SavedScreen(),
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
    GoRoute(
      path: '/ai-hub',
      builder: (context, state) => const AiHubScreen(),
    ),
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/organizations',
      builder: (context, state) => const OrganizationsHubScreen(),
    ),
    GoRoute(
      path: '/kaza-trust',
      builder: (context, state) => const KazaTrustScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/subscription-plans',
      builder: (context, state) => const SubscriptionPlansScreen(),
    ),
    GoRoute(
      path: '/basic-stats',
      builder: (context, state) => const BasicStatsScreen(),
    ),
    GoRoute(
      path: '/pro-dashboard',
      builder: (context, state) => const ProDashboardScreen(),
    ),
    GoRoute(
      path: '/crm-contacts',
      builder: (context, state) => const CrmContactsScreen(),
    ),
    GoRoute(
      path: '/crm-opportunities',
      builder: (context, state) => const CrmOpportunitiesScreen(),
    ),
    GoRoute(
      path: '/org-dashboard',
      builder: (context, state) => const BusinessDashboardScreen(),
    ),
    GoRoute(
      path: '/org-members',
      builder: (context, state) => const OrgMembersScreen(),
    ),
    GoRoute(
      path: '/org-properties',
      builder: (context, state) => const OrgPropertiesScreen(),
    ),
    GoRoute(
      path: '/org-opportunities',
      builder: (context, state) => const OrgOpportunitiesScreen(),
    ),
    GoRoute(
      path: '/tour-360-demo',
      builder: (context, state) => const Tour360Screen(
        url: 'https://my.matterport.com/show/?m=Jd2JBfwCQPT', // Demo Matterport link
        title: 'Penthouse - Tour 360°',
      ),
    ),
  ],
);
