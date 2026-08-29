import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../widgets/ai_disclaimer_sheet.dart';
import '../screens/ai_chat_screen.dart';

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
      backgroundColor: KazaTheme.azulKaza, // Todo el fondo oscuro según diseño
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
          children: [
            // Header / Saludo con círculo AI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Tu asistente inteligente para entender el mercado, propiedades y tomar mejores decisiones.',
                          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                        ),
                        SizedBox(height: 24),
                        Text(
                          '¿En qué puedo ayudarte hoy?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: KazaTheme.azulKaza,
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'AI',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Opciones del menú (Tarjetas blancas sobre fondo azul)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  _buildMenuOption(
                    context,
                    icon: Icons.analytics_outlined,
                    title: 'Analizar una propiedad',
                    subtitle: 'Resumen técnico y de contexto',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiChatScreen(
                          initialMessage: '¿Puedes darme un análisis completo del mercado inmobiliario en Bolivia? Incluye tendencias de precios, oferta y demanda, y las propiedades disponibles actualmente en KAZA.',
                        ),
                      ),
                    ),
                  ),
                  _buildMenuOption(
                    context,
                    icon: Icons.compare_arrows_rounded,
                    title: 'Comparar propiedades',
                    subtitle: 'Pros y contras lado a lado',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiChatScreen(
                          initialMessage: 'Quiero comparar las propiedades disponibles en KAZA. ¿Cuáles son las mejores opciones según precio, ubicación y características? Dame una comparación detallada.',
                        ),
                      ),
                    ),
                  ),
                  _buildMenuOption(
                    context,
                    icon: Icons.location_city_rounded,
                    title: 'Entender el entorno',
                    subtitle: 'Servicios, conectividad y más',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiChatScreen(
                          initialMessage: 'Quiero entender el entorno urbano de las zonas donde KAZA tiene propiedades en Bolivia. ¿Qué barrios tienen mejor infraestructura, servicios, conectividad y calidad de vida?',
                        ),
                      ),
                    ),
                  ),
                  _buildMenuOption(
                    context,
                    icon: Icons.trending_up_rounded,
                    title: 'Estimaciones de valor',
                    subtitle: 'Rango y metodología',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiChatScreen(
                          initialMessage: '¿Cuál es el rango de precios del mercado inmobiliario boliviano actualmente? Dame estimaciones de valor por zona, tipo de propiedad y tendencias de apreciación esperadas.',
                        ),
                      ),
                    ),
                  ),
                  _buildMenuOption(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: 'Planificar una visita',
                    subtitle: 'Itinerarios y tiempo estimado',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiChatScreen(
                          initialMessage: 'Quiero planificar visitas a propiedades en Bolivia. ¿Qué propiedades de KAZA me recomiendas visitar primero? Dame consejos sobre qué evaluar durante la visita y cómo organizarme.',
                        ),
                      ),
                    ),
                  ),
                  _buildMenuOption(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Otras preguntas',
                    subtitle: 'Asistente general de Kaza',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiChatScreen(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Texto final de advertencia
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Imagina puede cometer errores. Verifica siempre la información importante.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: KazaTheme.azulKaza, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: KazaTheme.azulKaza)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: KazaTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
