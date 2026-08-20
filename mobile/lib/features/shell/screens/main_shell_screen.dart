import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/utils/responsive_utils.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// 🏛️ MAIN SHELL SCREEN — 5-Tab Navigation (KAZA Master Design)
/// Tabs: Mapa, Buscar, Guardados, Comparar, Perfil
class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final bottomSafe = KazaResponsive.bottomSafeArea(context);
    final navHeight = KazaResponsive.bottomNavHeight(context);
    final screenWidth = KazaResponsive.screenWidth(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        height: navHeight + bottomSafe,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomSafe),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on_rounded,
                label: 'Mapa',
                currentIndex: currentIndex,
                screenWidth: screenWidth,
                onTap: () => navigationShell.goBranch(0),
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                label: 'Buscar',
                currentIndex: currentIndex,
                screenWidth: screenWidth,
                onTap: () => navigationShell.goBranch(1),
              ),
              
              // ── BOTÓN CENTRAL: PUBLICAR ─────────────────────────────
              _buildPublishItem(context, ref, screenWidth),
              
              _buildNavItem(
                index: 2,
                icon: Icons.compare_arrows_rounded,
                activeIcon: Icons.compare_arrows_rounded,
                label: 'Comparar',
                currentIndex: currentIndex,
                screenWidth: screenWidth,
                onTap: () => checkProgressiveAuth(
                  context: context,
                  ref: ref,
                  actionName: 'Comparar propiedades',
                  onAuthenticatedAction: () => navigationShell.goBranch(2),
                ),
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Perfil',
                currentIndex: currentIndex,
                screenWidth: screenWidth,
                onTap: () => navigationShell.goBranch(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int currentIndex,
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;
    // Hide label on very small screens to prevent overflow
    final showLabel = screenWidth >= 340;
    final iconSize = screenWidth < 360 ? 22.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? KazaTheme.azulKaza : KazaTheme.grisMedio,
              size: iconSize,
            ),
            if (showLabel) ...[
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? KazaTheme.azulKaza : KazaTheme.grisMedio,
                  fontSize: screenWidth < 380 ? 10 : 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildPublishItem(BuildContext context, WidgetRef ref, double screenWidth) {
    final showLabel = screenWidth >= 340;
    
    return GestureDetector(
      onTap: () {
        checkProgressiveAuth(
          context: context,
          ref: ref,
          actionName: 'Publicar una propiedad',
          onAuthenticatedAction: () => context.push('/publish'),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 32,
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
            if (showLabel) ...[
              const SizedBox(height: 3),
              Text(
                'Publicar',
                style: TextStyle(
                  color: KazaTheme.azulKaza,
                  fontSize: screenWidth < 380 ? 10 : 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
