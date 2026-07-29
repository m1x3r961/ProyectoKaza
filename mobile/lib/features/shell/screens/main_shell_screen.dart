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
    final bottomSafe = KazaResponsive.bottomSafeArea(context);

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

