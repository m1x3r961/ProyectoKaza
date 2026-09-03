import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../auth/providers/auth_provider.dart';

/// ⚙️ MENÚ DE AJUSTES (Lámina 06: Perfil y Cuenta)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Perfil y cuenta', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          _buildSectionHeader('01 Mi perfil'),
          _buildListTile(Icons.person_outline, 'Información personal', onTap: () => context.push('/personal-info')),
          _buildListTile(Icons.lock_outline, 'Seguridad y acceso', onTap: () => context.push('/security')),
          _buildListTile(Icons.notifications_none, 'Notificaciones', onTap: () => context.push('/notifications')),
          _buildListTile(Icons.tune, 'Preferencias', onTap: () => context.push('/preferences')),
          _buildListTile(Icons.stars_outlined, 'Cuenta y plan', onTap: () => context.push('/subscription-plans')),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Permisos y seguridad'),
          _buildListTile(Icons.shield_outlined, 'Permisos y privacidad', onTap: () => context.push('/privacy')),
          _buildListTile(Icons.verified_outlined, 'Verificación de identidad', onTap: () => context.push('/identity-verification')),
          _buildListTile(Icons.workspace_premium_outlined, 'Mis logros y reputación', onTap: () => context.push('/reputation')),
          _buildListTile(Icons.no_accounts_outlined, 'Eliminar o desactivar cuenta', onTap: () => context.push('/delete-account'), isDestructive: true),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Soporte'),
          _buildListTile(Icons.help_outline, 'Centro de ayuda', onTap: () => context.push('/help-center')),
          _buildListTile(
            Icons.logout, 
            'Cerrar sesión', 
            onTap: () => _showLogoutDialog(context, ref), 
            isDestructive: true
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('¿Segura que quieres cerrar sesión?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: KazaTheme.textPrimary)),
        content: const Text('Podrás iniciar sesión nuevamente cuando quieras.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(kazaAuthProvider.notifier).logout();
              Navigator.pop(ctx);
              context.pop(); // Go back from settings
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: KazaTheme.textMuted, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : KazaTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: color),
              ),
            ),
            Icon(Icons.chevron_right, color: KazaTheme.glassBorder, size: 24),
          ],
        ),
      ),
    );
  }
}
