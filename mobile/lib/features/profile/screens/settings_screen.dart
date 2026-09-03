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
          _buildListTile(Icons.person_outline, 'Información personal', onTap: () {}),
          _buildListTile(Icons.lock_outline, 'Seguridad y acceso', onTap: () {}),
          _buildListTile(Icons.notifications_none, 'Notificaciones', onTap: () {}),
          _buildListTile(Icons.tune, 'Preferencias', onTap: () {}),
          _buildListTile(Icons.stars_outlined, 'Cuenta y plan', onTap: () => context.push('/subscription-plans')),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Permisos y seguridad'),
          _buildListTile(Icons.shield_outlined, 'Permisos y privacidad', onTap: () {}),
          _buildListTile(Icons.verified_outlined, 'Verificación de identidad', onTap: () => context.push('/kaza-trust')),
          _buildListTile(Icons.workspace_premium_outlined, 'Mis logros y reputación', onTap: () {}),
          _buildListTile(Icons.no_accounts_outlined, 'Eliminar o desactivar cuenta', onTap: () {}, isDestructive: true),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Soporte'),
          _buildListTile(Icons.help_outline, 'Centro de ayuda', onTap: () {}),
          _buildListTile(
            Icons.logout, 
            'Cerrar sesión', 
            onTap: () {
              ref.read(kazaAuthProvider.notifier).logout();
              context.pop();
            }, 
            isDestructive: true
          ),
          
          const SizedBox(height: 48),
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
