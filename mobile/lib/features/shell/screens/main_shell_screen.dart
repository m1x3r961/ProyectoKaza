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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: KazaTheme.cardSurface,
          border: Border(
            top: BorderSide(color: KazaTheme.glassBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            // Requerir autenticación para publicar (index 2) o ver mensajes (index 3)
            if (index == 2 || index == 3) {
              checkProgressiveAuth(
                context: context,
                ref: ref,
                actionName: index == 2 ? 'Publicar un Inmueble' : 'Ver tus Mensajes y Chats',
                onAuthenticatedAction: () {
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
              );
            } else {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            }
          },
          selectedItemColor: KazaTheme.primaryTealLight,
          unselectedItemColor: KazaTheme.textMuted,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map, color: KazaTheme.primaryTealLight),
              label: 'MAPA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              activeIcon: Icon(Icons.bookmark, color: KazaTheme.primaryTealLight),
              label: 'GUARDADOS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 28, color: KazaTheme.accentGold),
              activeIcon: Icon(Icons.add_circle, size: 28, color: KazaTheme.accentGold),
              label: '+ PUBLICAR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble, color: KazaTheme.primaryTealLight),
              label: 'MENSAJES',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: KazaTheme.primaryTealLight),
              label: 'PERFIL',
            ),
          ],
        ),
      ),
    );
  }
}
