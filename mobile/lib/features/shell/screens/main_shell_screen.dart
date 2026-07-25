import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// 🏛️ MAIN SHELL SCREEN - 5-Tab Bottom Navigation Host
class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 72,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.location_on_outlined,
              activeIcon: Icons.location_on_rounded,
              label: 'Mapa',
              currentIndex: currentIndex,
              onTap: () => navigationShell.goBranch(0),
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.favorite_border_rounded,
              activeIcon: Icons.favorite_rounded,
              label: 'Guardados',
              currentIndex: currentIndex,
              onTap: () => navigationShell.goBranch(1),
            ),
            // Center Floating Action Button (+ Publicar) in Coral Kaza #FF5A3C
            GestureDetector(
              onTap: () {
                checkProgressiveAuth(
                  context: context,
                  ref: ref,
                  actionName: 'Publicar un Inmueble',
                  onAuthenticatedAction: () {
                    navigationShell.goBranch(2);
                  },
                );
              },
              child: Container(
                width: 52,
                height: 52,
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
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'Mensajes',
              currentIndex: currentIndex,
              onTap: () {
                checkProgressiveAuth(
                  context: context,
                  ref: ref,
                  actionName: 'Ver tus Mensajes',
                  onAuthenticatedAction: () {
                    navigationShell.goBranch(3);
                  },
                );
              },
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Perfil',
              currentIndex: currentIndex,
              onTap: () => navigationShell.goBranch(4),
            ),
          ],
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
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? KazaTheme.azulKaza : KazaTheme.grisMedio,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? KazaTheme.azulKaza : KazaTheme.grisMedio,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
