import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../auth/providers/auth_provider.dart';

/// ⚙️ PANTALLA DE AJUSTES (Settings)
/// Aquí se agrupan las opciones genéricas de configuración que fueron retiradas de la vista principal del perfil.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(kazaAuthProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Ajustes', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          const Text('Configuración y soporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 16),
          _buildListTile('Cuentas vinculadas', onTap: () {}),
          _buildListTile('Seguridad', onTap: () {}),
          _buildListTile('Privacidad', onTap: () {}),
          _buildListTile('Notificaciones', onTap: () {}),
          _buildListTile('Plan y suscripción', onTap: () => context.push('/subscription-plans')),
          _buildListTile('Mis Organizaciones', onTap: () => context.push('/organizations')),
          _buildListTile('Verificación KAZA Trust', onTap: () => context.push('/kaza-trust')),

          const SizedBox(height: 48),

          if (authState.isAuthenticated)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
              onTap: () {
                ref.read(kazaAuthProvider.notifier).logout();
                context.pop();
              },
            ),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Eliminar cuenta', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: KazaTheme.textPrimary)),
            const Icon(Icons.chevron_right, color: KazaTheme.grisMedio, size: 20),
          ],
        ),
      ),
    );
  }
}
