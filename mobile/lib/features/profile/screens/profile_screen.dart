import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../auth/providers/auth_provider.dart';

/// 👤 PERFIL v1.0 (Lámina 06: Mi perfil)
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(kazaAuthProvider);
    final isAuthenticated = authState.isAuthenticated;
    final userName = isAuthenticated ? (authState.fullName ?? 'Ana Rodríguez') : 'Ana Rodríguez';
    final userEmail = isAuthenticated ? (authState.email ?? 'ana@kaza.com') : 'ana@bienesraices.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Mi perfil', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: KazaTheme.textPrimary),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined, color: KazaTheme.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: KazaTheme.grisClaro,
                  // Placeholder for image
                  child: Icon(Icons.person, size: 40, color: KazaTheme.grisMedio),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: KazaTheme.textPrimary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: KazaTheme.azulKaza, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Agente Inmobiliario', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                          const SizedBox(width: 4),
                          const Row(
                            children: [
                              Icon(Icons.star, color: KazaTheme.accentGold, size: 14),
                              Icon(Icons.star, color: KazaTheme.accentGold, size: 14),
                              Icon(Icons.star, color: KazaTheme.accentGold, size: 14),
                              Icon(Icons.star, color: KazaTheme.accentGold, size: 14),
                              Icon(Icons.star_half, color: KazaTheme.accentGold, size: 14),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Text('(124)', style: TextStyle(color: KazaTheme.textSecondary.withValues(alpha: 0.8), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ESTADÍSTICAS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('28', 'Publicaciones'),
                Container(height: 40, width: 1, color: KazaTheme.glassBorder),
                _buildStatColumn('156', 'Guardados'),
                Container(height: 40, width: 1, color: KazaTheme.glassBorder),
                _buildStatColumn('24', 'Visitas'),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: KazaTheme.glassBorder, height: 1),
            ),

            // SOBRE MÍ
            const Text('Sobre mí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
            const SizedBox(height: 12),
            const Text(
              'Especialista en zonas norte y este de Santa Cruz.\nMás de 5 años de experiencia.',
              style: TextStyle(color: KazaTheme.textPrimary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text('Idiomas: ES - EN', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: KazaTheme.glassBorder, height: 1),
            ),

            // CONTACTO
            const Text('Contacto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
            const SizedBox(height: 16),
            _buildContactRow(Icons.phone_outlined, '+591 700 12345'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.email_outlined, userEmail),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: KazaTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: KazaTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: KazaTheme.textPrimary, fontSize: 14)),
      ],
    );
  }
}
