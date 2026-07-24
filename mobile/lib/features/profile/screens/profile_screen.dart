import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../../auth/providers/auth_provider.dart';

/// 👤 PERFIL Y WORKSPACES - User Account, Active Workspace Switcher & Settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(kazaAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil & Cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card / Auth Status Banner
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: authState.isAuthenticated ? KazaTheme.primaryTeal : Colors.grey.shade800,
                    child: Icon(
                      authState.isAuthenticated ? Icons.person : Icons.person_outline,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.isAuthenticated
                              ? (authState.fullName ?? 'Usuario Kaza')
                              : 'Modo Exploración (Sin Cuenta)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          authState.isAuthenticated
                              ? (authState.email ?? 'user@kaza.app')
                              : 'Regístrate solo cuando desees conservar o avanzar',
                          style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        if (authState.isAuthenticated)
                          const KazaTrustBadge(label: 'Identidad Verificada')
                        else
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                            child: const Text('Iniciar Sesión / Registrarme', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              checkProgressiveAuth(
                                context: context,
                                ref: ref,
                                actionName: 'acceder a tu Perfil completo',
                                onAuthenticatedAction: () {},
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Workspace Switcher
          const Text('Workspace Activo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Card(
            color: KazaTheme.cardSurface,
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Personal Workspace'),
                  subtitle: const Text('Publicaciones personales y guardados privados'),
                  value: 'Personal Workspace',
                  groupValue: authState.activeWorkspaceName,
                  activeColor: KazaTheme.primaryTealLight,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(kazaAuthProvider.notifier).switchWorkspace(val, false);
                    }
                  },
                ),
                const Divider(height: 1, color: KazaTheme.glassBorder),
                RadioListTile<String>(
                  title: const Row(
                    children: [
                      Text('Inmobiliaria Kaza Pro'),
                      SizedBox(width: 8),
                      KazaPlusBadge(),
                    ],
                  ),
                  subtitle: const Text('Organization Workspace · 12 Listings activos'),
                  value: 'Inmobiliaria Kaza Pro',
                  groupValue: authState.activeWorkspaceName,
                  activeColor: KazaTheme.primaryTealLight,
                  onChanged: (val) {
                    if (val != null) {
                      checkProgressiveAuth(
                        context: context,
                        ref: ref,
                        actionName: 'gestionar un Organization Workspace',
                        onAuthenticatedAction: () {
                          ref.read(kazaAuthProvider.notifier).switchWorkspace(val, true);
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Activity Center & Options
          const Text('Centro de Actividad & Ajustes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),

          _buildMenuOption(Icons.history, 'Histórico de Transacciones', 'Transaction Claims & DOM'),
          _buildMenuOption(Icons.analytics, 'Kaza Insights & Métricas', 'Precios/m² y comparables'),
          _buildMenuOption(Icons.verified_user, 'Verificación de Identidad (Trust)', 'Badges y evidencia legal'),
          _buildMenuOption(Icons.privacy_tip, 'Privacidad & Términos de Uso', 'Global Privacy Rights Center'),

          const SizedBox(height: 24),

          // Logout or Account Deletion
          if (authState.isAuthenticated) ...[
            Card(
              color: Colors.red.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text('Volver al modo de exploración pública sin cuenta', style: TextStyle(fontSize: 11)),
                onTap: () {
                  ref.read(kazaAuthProvider.notifier).logout();
                },
              ),
            ),
          ] else ...[
            Card(
              color: Colors.red.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Eliminar Mi Cuenta', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text('Ruta de eliminación de cuenta accesible exigida por políticas de tienda', style: TextStyle(fontSize: 11)),
                onTap: () {
                  checkProgressiveAuth(
                    context: context,
                    ref: ref,
                    actionName: 'solicitar la eliminación de cuenta',
                    onAuthenticatedAction: () {},
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: KazaTheme.primaryTealLight),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: KazaTheme.textMuted),
        onTap: () {},
      ),
    );
  }
}
