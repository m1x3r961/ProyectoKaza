import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/utils/responsive_utils.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// 🏛️ MAIN SHELL SCREEN — Responsive Navigation Host
/// • Phone  (<600px) : Bottom navigation bar con FAB central
/// • Tablet (≥600px) : NavigationRail lateral + FAB en rail
class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final isTablet = KazaResponsive.isTablet(context);
    final bottomSafe = KazaResponsive.bottomSafeArea(context);

    // ── TABLET: NavigationRail lateral ────────────────────────────────────
    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.white,
              selectedIndex: currentIndex == 2 ? 0 : // FAB "Publicar" no tiene rail item
                  (currentIndex > 2 ? currentIndex - 1 : currentIndex),
              onDestinationSelected: (idx) {
                // Ajustar índice para saltar el slot "Publicar" (index 2)
                final branch = idx >= 2 ? idx + 1 : idx;
                if (branch == 3) {
                  // Mensajes requiere auth
                  checkProgressiveAuth(
                    context: context,
                    ref: ref,
                    actionName: 'Ver tus Mensajes',
                    onAuthenticatedAction: () => navigationShell.goBranch(3),
                  );
                } else {
                  navigationShell.goBranch(branch);
                }
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // Logo Kaza
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: KazaTheme.coralKaza,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 16),
                    // FAB Publicar en tablet
                    GestureDetector(
                      onTap: () => checkProgressiveAuth(
                        context: context,
                        ref: ref,
                        actionName: 'Publicar un Inmueble',
                        onAuthenticatedAction: () => navigationShell.goBranch(2),
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: KazaTheme.coralKaza,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x44FF5A3C),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: const TextStyle(
                color: KazaTheme.coralKaza,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: KazaTheme.grisMedio,
                fontSize: 11,
              ),
              selectedIconTheme: const IconThemeData(color: KazaTheme.coralKaza, size: 26),
              unselectedIconTheme: const IconThemeData(color: KazaTheme.grisMedio, size: 24),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.location_on_outlined),
                  selectedIcon: Icon(Icons.location_on_rounded),
                  label: Text('Mapa'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: Text('Guardados'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: Text('Mensajes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Perfil'),
                ),
              ],
            ),
            // Separador vertical
            const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),
            // Contenido principal
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // ── PHONE: Bottom nav bar ─────────────────────────────────────────────
    final navHeight = KazaResponsive.bottomNavHeight(context);
    final screenWidth = KazaResponsive.screenWidth(context);
    // En pantallas muy pequeñas (< 360px) reducir el FAB
    final fabSize = screenWidth < 360 ? 44.0 : 52.0;
    final fabIconSize = screenWidth < 360 ? 26.0 : 32.0;

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
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Guardados',
                currentIndex: currentIndex,
                screenWidth: screenWidth,
                onTap: () => navigationShell.goBranch(1),
              ),
              // FAB central "Publicar"
              GestureDetector(
                onTap: () => checkProgressiveAuth(
                  context: context,
                  ref: ref,
                  actionName: 'Publicar un Inmueble',
                  onAuthenticatedAction: () => navigationShell.goBranch(2),
                ),
                child: Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: const BoxDecoration(
                    color: KazaTheme.coralKaza,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x55FF5A3C),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: fabIconSize,
                  ),
                ),
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Mensajes',
                currentIndex: currentIndex,
                screenWidth: screenWidth,
                onTap: () => checkProgressiveAuth(
                  context: context,
                  ref: ref,
                  actionName: 'Ver tus Mensajes',
                  onAuthenticatedAction: () => navigationShell.goBranch(3),
                ),
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Perfil',
                currentIndex: currentIndex,
                screenWidth: screenWidth,
                onTap: () => navigationShell.goBranch(4),
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
    // Ocultar label en pantallas muy pequeñas para evitar overflow
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
}

