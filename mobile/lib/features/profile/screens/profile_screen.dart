import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/supabase_config.dart';
import '../../developer/providers/developer_provider.dart';

/// 👤 PERFIL U18-A v0.6 FINAL
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedContext = 'Personal';
  String _tier = 'FREE';
  String? _role;
  String? _bio;
  double _rating = 0;
  int _totalReviews = 0;
  int _publicationsCount = 0;
  int _visitsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTier();
  }

  Future<void> _loadTier() async {
    final auth = ref.read(kazaAuthProvider);
    if (auth.userId == null) return;
    try {
      // 1. Tier de suscripción
      final resp = await SupabaseConfig.client
          .from('profiles')
          .select('subscription_tier')
          .eq('id', auth.userId!)
          .maybeSingle();
      if (resp != null && mounted) {
        setState(() => _tier = resp['subscription_tier'] ?? 'FREE');
      }

      // 2. Perfil profesional (datos reales)
      final profResp = await SupabaseConfig.client
          .from('professional_profiles')
          .select()
          .eq('id', auth.userId!)
          .maybeSingle();
      if (profResp != null && mounted) {
        setState(() {
          _role = profResp['role'];
          _bio = profResp['bio'];
          _rating = (profResp['rating'] ?? 0).toDouble();
          _totalReviews = profResp['total_reviews'] ?? 0;
        });
      }

      // 3. Contadores reales de publicaciones
      try {
        final pubResp = await SupabaseConfig.client
            .from('properties')
            .select('id')
            .eq('owner_id', auth.userId!);
        if (mounted) {
          setState(() => _publicationsCount = (pubResp as List).length);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error al cargar tier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(kazaAuthProvider);
    final isAuthenticated = authState.isAuthenticated;
    final userName = isAuthenticated ? (authState.fullName ?? 'Usuario KAZA') : 'Modo Explorador';
    // Generar un username temporal a partir del email para mockear el diseño
    final userHandle = isAuthenticated && authState.email != null 
        ? '@${authState.email!.split('@')[0].toLowerCase()}' 
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo gris muy claro para contraste con tarjetas
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Perfil', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: KazaTheme.textSecondary),
            label: const Text('Vista pública', style: TextStyle(color: KazaTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined, color: KazaTheme.textPrimary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. TARJETA PRINCIPAL (Identidad)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: KazaTheme.grisClaro,
                      child: const Icon(Icons.person, size: 40, color: KazaTheme.grisMedio),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: KazaTheme.textPrimary, letterSpacing: -0.5)),
                          if (userHandle.isNotEmpty)
                            Text(userHandle, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                          const SizedBox(height: 8),
                          if (isAuthenticated) ...[
                            Row(
                              children: [
                                const Icon(Icons.verified, color: KazaTheme.verifiedGreen, size: 16),
                                const SizedBox(width: 4),
                                const Text('Identidad verificada', style: TextStyle(color: KazaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Cuenta $_tier', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                final result = await context.push('/subscription-plans');
                                if (result is String) setState(() => _tier = result);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: KazaTheme.accentGold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: KazaTheme.accentGold.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stars_rounded, color: KazaTheme.accentGold, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      _tier == 'FREE' ? 'Mejorar a Plus' : 'Cambiar Plan',
                                      style: const TextStyle(color: KazaTheme.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: KazaTheme.glassBorder, height: 1),
                ),

                // 2. CONTEXTO ACTUAL
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contexto actual', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(radius: 16, backgroundColor: KazaTheme.n100, child: Icon(Icons.person, size: 16, color: KazaTheme.textSecondary)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
                              Text('Uso individual de KAZA', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.expand_more, color: KazaTheme.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildContextPill('Personal', isSelected: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildContextPill('Profesional', isSelected: false)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildContextPill('Organización', isSelected: false)),
                      ],
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: KazaTheme.glassBorder, height: 1),
                ),

                // 3. SEÑALES DE CONFIANZA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Señales de confianza', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                    const Icon(Icons.info_outline, size: 16, color: KazaTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTrustSignal(Icons.shield_outlined, 'Trust', 'Señales de legitimidad', KazaTheme.verifiedGreen)),
                    Expanded(child: _buildTrustSignal(Icons.check_circle_outline, 'Verification', 'Hechos verificados', KazaTheme.azulKaza)),
                    Expanded(child: _buildTrustSignal(Icons.star_outline, 'Reputation', 'Trayectoria', KazaTheme.accentGold)),
                    Expanded(
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.workspace_premium, size: 16, color: KazaTheme.primaryCoral),
                              Icon(Icons.workspace_premium, size: 16, color: KazaTheme.primaryCoral),
                              Icon(Icons.workspace_premium, size: 16, color: KazaTheme.primaryCoral),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Logros destacados\nMáx. 3', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Ver todos >', style: TextStyle(color: KazaTheme.azulKaza, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: KazaTheme.glassBorder, height: 1),
                ),

                // 4. NAVEGACIÓN PRINCIPAL (Datos reales de BD)
                _buildMainNavItem(
                  icon: Icons.home_work_outlined, 
                  title: 'Mis publicaciones', 
                  subtitle: '$_publicationsCount activas',
                  onTap: () => context.push('/my-listings'),
                ),
                _buildMainNavItem(
                  icon: Icons.remove_red_eye_outlined, 
                  title: 'Mis visitas', 
                  subtitle: '$_visitsCount confirmadas',
                  onTap: () {},
                ),
                _buildMainNavItem(
                  icon: Icons.show_chart_rounded, 
                  title: 'Actividad relevante', 
                  subtitle: 'Visitas, contactos y mensajes',
                  onTap: () => context.push('/basic-stats'),
                ),
                if (_tier == 'PRO' || _tier == 'BUSINESS')
                  _buildMainNavItem(
                    icon: Icons.work_outline, 
                    title: 'CRM Profesional', 
                    subtitle: 'Contactos y oportunidades',
                    onTap: () => context.push('/pro-dashboard'),
                  ),
                if (_tier == 'BUSINESS')
                  _buildMainNavItem(
                    icon: Icons.construction, 
                    title: 'Panel Desarrolladora', 
                    subtitle: 'Gestiona tus proyectos inmobiliarios',
                    onTap: () => context.push('/developer-dashboard'),
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: KazaTheme.glassBorder, height: 1),
                ),

                // 5. ACCESOS Y CAPACIDADES
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Accesos y capacidades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAccessIcon(Icons.work, 'Perfil\nprofesional'),
                    _buildAccessIcon(Icons.business, 'Organizaciones\ny membresías'),
                    _buildAccessIcon(Icons.swap_horiz, 'Cambiar\ncontexto'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40), // Spacing for bottom nav
        ],
      ),
    );
  }

  Widget _buildContextPill(String title, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? KazaTheme.azulKaza : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? KazaTheme.azulKaza : KazaTheme.glassBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : KazaTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTrustSignal(IconData icon, String title, String subtitle, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: KazaTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: KazaTheme.textSecondary)),
      ],
    );
  }

  Widget _buildMainNavItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: KazaTheme.azulKaza, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: KazaTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KazaTheme.n100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: KazaTheme.primaryCoral),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
