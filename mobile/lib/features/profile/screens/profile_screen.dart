import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../../auth/providers/auth_provider.dart';

/// 👤 PERFIL - User Account (v0.2 HiFi Light Theme)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(kazaAuthProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: KazaTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          // 1. User Header (Avatar, Name, Status)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: authState.isAuthenticated ? KazaTheme.primaryCoralLight.withValues(alpha: 0.1) : KazaTheme.grisClaro,
                child: Icon(
                  authState.isAuthenticated ? Icons.person : Icons.person_outline,
                  size: 36,
                  color: authState.isAuthenticated ? KazaTheme.primaryCoralLight : KazaTheme.grisMedio,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.isAuthenticated ? (authState.fullName ?? 'Usuario Kaza') : 'Modo Exploración',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: KazaTheme.textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authState.isAuthenticated ? 'Cuenta personal' : 'Sin cuenta',
                      style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    if (authState.isAuthenticated)
                      const Row(
                        children: [
                          Icon(Icons.verified, color: KazaTheme.verifiedGreen, size: 16),
                          SizedBox(width: 4),
                          Text('Identidad verificada', style: TextStyle(color: KazaTheme.verifiedGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          checkProgressiveAuth(context: context, ref: ref, actionName: 'iniciar sesión', onAuthenticatedAction: () {});
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.login, color: KazaTheme.primaryCoralLight, size: 16),
                            SizedBox(width: 4),
                            Text('Iniciar sesión o registrarme', style: TextStyle(color: KazaTheme.primaryCoralLight, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // 2. Sección: Tu actividad
          const Text('Tu actividad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KazaTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          
          _buildCleanListTile(
            title: 'Mis publicaciones',
            onTap: () {
              checkProgressiveAuth(context: context, ref: ref, actionName: 'ver tus publicaciones', onAuthenticatedAction: () {});
            },
          ),
          _buildCleanListTile(
            title: 'Mis visitas',
            onTap: () {
              checkProgressiveAuth(context: context, ref: ref, actionName: 'ver tus visitas', onAuthenticatedAction: () {});
            },
          ),
          _buildCleanListTile(
            title: 'Guardados',
            onTap: () {},
          ),
          _buildCleanListTile(
            title: 'Actividad',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // 3. Sección: Más herramientas
          const Text('Más herramientas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KazaTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 8),

          _buildCleanListTile(
            title: 'Herramientas para publicar y trabajar',
            onTap: () {
              checkProgressiveAuth(context: context, ref: ref, actionName: 'acceder a herramientas profesionales', onAuthenticatedAction: () {});
            },
          ),
          _buildCleanListTile(
            title: 'Cuenta y privacidad',
            onTap: () {},
          ),

          const SizedBox(height: 48),

          // Logout / Delete Account (Modern minimal style)
          if (authState.isAuthenticated)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
              onTap: () {
                ref.read(kazaAuthProvider.notifier).logout();
              },
            )
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Eliminar cuenta', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
              onTap: () {
                checkProgressiveAuth(context: context, ref: ref, actionName: 'solicitar la eliminación de cuenta', onAuthenticatedAction: () {});
              },
            ),
            
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCleanListTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: KazaTheme.textPrimary),
            ),
            const Icon(Icons.chevron_right, color: KazaTheme.grisMedio, size: 20),
          ],
        ),
      ),
    );
  }
}
