import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';

/// 💳 PLANES DE SUSCRIPCIÓN (U05 / U06)
class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  bool _isLoading = false;
  String _currentTier = 'FREE';

  @override
  void initState() {
    super.initState();
    _loadCurrentTier();
  }

  Future<void> _loadCurrentTier() async {
    try {
      final auth = ref.read(kazaAuthProvider);
      if (auth.userId == null) return;
      
      final resp = await SupabaseConfig.client
          .from('profiles')
          .select('subscription_tier')
          .eq('id', auth.userId!)
          .maybeSingle();
          
      if (resp != null && resp['subscription_tier'] != null) {
        if (mounted) setState(() => _currentTier = resp['subscription_tier'] as String);
      }
    } catch (e) {
      debugPrint('Error cargando tier: $e');
    }
  }

  Future<void> _upgradePlan(String newTier) async {
    setState(() => _isLoading = true);
    try {
      // Usar la RPC definida en la migración 00014
      await SupabaseConfig.client.rpc('fn_upgrade_subscription', params: {'p_tier': newTier});
      
      if (mounted) {
        setState(() => _currentTier = newTier);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Felicidades! Ahora tienes una cuenta $newTier.'),
            backgroundColor: KazaTheme.semanticSuccess,
          ),
        );
        // Regresar y forzar un redibujo si es necesario
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar plan: $e'), backgroundColor: KazaTheme.semanticError),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Planes y Suscripciones', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: KazaTheme.accentGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Mejora tu cuenta KAZA',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Obtén más alcance, mejores herramientas de gestión y conviértete en un profesional.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  
                  // PLAN FREE
                  _buildPlanCard(
                    title: 'FREE',
                    price: 'Gratis',
                    description: 'Para explorar y publicar lo esencial.',
                    isActive: _currentTier == 'FREE',
                    features: [
                      'Publicar hasta 2 propiedades',
                      'Comparar hasta 3 inmuebles',
                      'Búsqueda y guardados ilimitados',
                    ],
                    onSelect: () => _upgradePlan('FREE'),
                    color: KazaTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  
                  // PLAN PLUS
                  _buildPlanCard(
                    title: 'PLUS',
                    price: 'Bs 150 / mes',
                    description: 'Más capacidad para publicar. Más alcance.',
                    isActive: _currentTier == 'PLUS',
                    features: [
                      'Publicaciones activas ilimitadas',
                      'Estadísticas de rendimiento básicas',
                      'Destacados en búsquedas',
                      'Gestión de propiedades mejorada',
                    ],
                    onSelect: () => _upgradePlan('PLUS'),
                    color: KazaTheme.accentGold,
                    isPopular: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // PLAN PRO
                  _buildPlanCard(
                    title: 'PRO',
                    price: 'Bs 300 / mes',
                    description: 'CRM y herramientas para agentes profesionales.',
                    isActive: _currentTier == 'PRO',
                    features: [
                      'Todo lo de Plus',
                      'CRM Inmobiliario Profesional',
                      'Embudo de oportunidades y ventas',
                      'Seguimiento y tareas inteligentes',
                      'Reportes avanzados y analítica',
                    ],
                    onSelect: () => _upgradePlan('PRO'),
                    color: KazaTheme.primaryCoral,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String description,
    required bool isActive,
    required List<String> features,
    required VoidCallback onSelect,
    required Color color,
    bool isPopular = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : KazaTheme.glassBorder, 
          width: isActive ? 2 : 1
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0, right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: const Text('MÁS POPULAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: KazaTheme.verifiedGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Text('PLAN ACTUAL', style: TextStyle(color: KazaTheme.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: KazaTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 24),
                
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded, color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: const TextStyle(color: KazaTheme.textPrimary, fontSize: 14))),
                    ],
                  ),
                )),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? KazaTheme.n100 : color,
                      foregroundColor: isActive ? KazaTheme.textMuted : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: isActive ? 0 : 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isActive ? null : onSelect,
                    child: Text(
                      isActive ? 'Plan Actual' : 'Seleccionar $title',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
