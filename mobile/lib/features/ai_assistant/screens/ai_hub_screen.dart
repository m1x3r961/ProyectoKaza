import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../widgets/ai_disclaimer_sheet.dart';

/// 01 HUB IMAGINA (Pantalla principal del asistente)
class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  void _showDisclaimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiDisclaimerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.azulKaza, // Fondo oscuro (Navy)
      appBar: AppBar(
        backgroundColor: KazaTheme.azulKaza,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: KazaTheme.coralKaza, size: 20),
            const SizedBox(width: 8),
            const Text(
              'KAZA Imagina',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: KazaTheme.coralKaza,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('BETA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            onPressed: () => _showDisclaimer(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / Saludo
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu asistente inteligente para entender el mercado, propiedades y tomar mejores decisiones.',
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '¿En qué puedo ayudarte hoy?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            
            // Opciones del menú (Lista con cards blancas)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: KazaTheme.lightBackground, // Blanco grisaceo
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildMenuOption(
                      context,
                      icon: Icons.analytics_outlined,
                      title: 'Analizar una propiedad',
                      subtitle: 'Resumen técnico y de contexto',
                      onTap: () {
                        // Lógica futura para seleccionar propiedad a analizar
                      },
                    ),
                    _buildMenuOption(
                      context,
                      icon: Icons.compare_arrows_rounded,
                      title: 'Comparar propiedades',
                      subtitle: 'Pros y contras lado a lado',
                      onTap: () {},
                    ),
                    _buildMenuOption(
                      context,
                      icon: Icons.location_city_rounded,
                      title: 'Entender el entorno',
                      subtitle: 'Servicios, conectividad y más',
                      onTap: () {},
                    ),
                    _buildMenuOption(
                      context,
                      icon: Icons.trending_up_rounded,
                      title: 'Estimaciones de valor',
                      subtitle: 'Rango y metodología',
                      onTap: () {},
                    ),
                    _buildMenuOption(
                      context,
                      icon: Icons.calendar_month_outlined,
                      title: 'Planificar una visita',
                      subtitle: 'Itinerarios y tiempo estimado',
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    // Chat libre option
                    GestureDetector(
                      onTap: () => context.push('/ai-chat'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [KazaTheme.azulKaza, Color(0xFF1E3A5F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Otras preguntas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Conversa libremente', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'Imagina puede cometer errores.\nVerifica siempre la información importante.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KazaTheme.coralKaza.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: KazaTheme.coralKaza, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
                      Text(subtitle, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: KazaTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
