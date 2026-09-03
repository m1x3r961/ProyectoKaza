import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Centro de ayuda', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: KazaTheme.grisClaro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Buscar ayuda...',
                hintStyle: TextStyle(color: KazaTheme.textSecondary),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: KazaTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          const Text('Temas populares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 16),
          
          _buildHelpTopic(Icons.home_work_outlined, 'Publicar una propiedad'),
          _buildHelpTopic(Icons.verified_outlined, 'Verificación de identidad'),
          _buildHelpTopic(Icons.payment_outlined, 'Planes y pagos'),
          _buildHelpTopic(Icons.visibility_outlined, 'Visitas y contactos'),
          _buildHelpTopic(Icons.shield_outlined, 'Privacidad y seguridad'),
          
          const SizedBox(height: 48),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: KazaTheme.glassBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.headset_mic_outlined, size: 32, color: KazaTheme.azulKaza),
                const SizedBox(height: 16),
                const Text('¿Necesitas más ayuda?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
                const SizedBox(height: 8),
                const Text('Contactar soporte', style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Te conectaremos con lo que necesites', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTopic(IconData icon, String title) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: KazaTheme.textPrimary, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: KazaTheme.textPrimary))),
            const Icon(Icons.chevron_right, color: KazaTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
