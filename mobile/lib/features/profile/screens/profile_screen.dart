import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../../auth/providers/auth_provider.dart';

/// 👤 PERFIL v0.3 FINAL (Perfil público y Cuenta privada)
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedCapacity = 'Agente'; // Propietario, Agente, Miembro de inmobiliaria

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(kazaAuthProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Perfil', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Vista pública', style: TextStyle(color: KazaTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          // 1. Perfil Público (Header)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: KazaTheme.grisClaro,
                child: const Icon(Icons.person, size: 40, color: KazaTheme.grisMedio),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.isAuthenticated ? (authState.fullName ?? 'Carlos Méndez') : 'Modo Exploración',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: KazaTheme.textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authState.isAuthenticated ? 'Agente independiente' : 'Sin cuenta',
                      style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (authState.isAuthenticated)
                      const Row(
                        children: [
                          Icon(Icons.verified, color: KazaTheme.verifiedGreen, size: 16),
                          SizedBox(width: 4),
                          Text('Identidad verificada', style: TextStyle(color: KazaTheme.verifiedGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                          SizedBox(width: 12),
                          Text('Desarrollador contextual', style: TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
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

          const SizedBox(height: 32),
          const Divider(color: KazaTheme.glassBorder),
          const SizedBox(height: 24),

          // 2. Capacidades y contextos
          const Text('Capacidades y contextos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCapacityPill('Propietario'),
              const SizedBox(width: 8),
              _buildCapacityPill('Agente'),
              const SizedBox(width: 8),
              _buildCapacityPill('Miembro de inmobiliaria'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Cambiar contexto no cambia la identidad de tu cuenta.', style: TextStyle(color: KazaTheme.textMuted, fontSize: 12)),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                checkProgressiveAuth(
                  context: context,
                  ref: ref,
                  actionName: 'Ver tus Guardados',
                  onAuthenticatedAction: () => context.push('/saved'),
                );
              },
              icon: const Icon(Icons.favorite_border_rounded, color: KazaTheme.azulKaza),
              label: const Text('Propiedades guardadas', style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: KazaTheme.azulKaza),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                checkProgressiveAuth(
                  context: context,
                  ref: ref,
                  actionName: 'Ver tus solicitudes de financiamiento',
                  onAuthenticatedAction: () => context.push('/financing-requests'),
                );
              },
              icon: const Icon(Icons.account_balance_outlined, color: KazaTheme.azulKaza),
              label: const Text('Solicitudes de financiamiento', style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: KazaTheme.azulKaza),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_selectedCapacity == 'Propietario' || _selectedCapacity == 'Agente') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/my-listings'),
                icon: const Icon(Icons.maps_home_work_outlined, color: Colors.redAccent),
                label: const Text('Gestionar mis publicaciones', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],

          const SizedBox(height: 32),

          // 3. Logros destacados
          const Text('Logros destacados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 16),
          _buildAchievementItem('Perfil completo', 'Muy bien!', Colors.redAccent),
          _buildAchievementItem('Respuesta constante', 'Muy bien!', Colors.orange),
          _buildAchievementItem('Sello Kaza', 'Otorgado', Colors.redAccent),
          
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
            child: const Text('Ver todos los logros >', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 32),
          const Divider(color: KazaTheme.glassBorder),
          const SizedBox(height: 24),

          // 4. Cuenta privada
          const Text('Cuenta privada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 16),
          
          _buildCleanListTile(title: 'Cuentas vinculadas', onTap: () {}),
          _buildCleanListTile(title: 'Seguridad', onTap: () {}),
          _buildCleanListTile(title: 'Privacidad', onTap: () {}),
          _buildCleanListTile(title: 'Notificaciones', onTap: () {}),
          _buildCleanListTile(title: 'Plan y suscripción', onTap: () {}),

          const SizedBox(height: 48),

          // Logout / Delete Account (Modern minimal style)
          if (authState.isAuthenticated)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
              onTap: () {
                ref.read(kazaAuthProvider.notifier).logout();
              },
            ),
          
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

  Widget _buildCapacityPill(String title) {
    final isSelected = _selectedCapacity == title;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCapacity = title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.redAccent : KazaTheme.glassBorder, width: isSelected ? 1.5 : 1.0),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.redAccent : KazaTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementItem(String title, String subtitle, Color stripColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, decoration: BoxDecoration(color: stripColor, borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: KazaTheme.textPrimary, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
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
