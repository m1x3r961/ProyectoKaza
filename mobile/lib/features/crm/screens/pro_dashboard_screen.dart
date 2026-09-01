import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';

/// 📈 PANEL PROFESIONAL (U06 AGENTE PRO)
class ProDashboardScreen extends ConsumerStatefulWidget {
  const ProDashboardScreen({super.key});

  @override
  ConsumerState<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends ConsumerState<ProDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Centro de control PRO', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido a tu panel profesional.',
              style: TextStyle(fontSize: 16, color: KazaTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // MÉTRICAS PRINCIPALES
            Row(
              children: [
                Expanded(child: _buildMetricCard('Clientes', '12', Icons.people_outline)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Oportunidades', '8', Icons.filter_alt_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Cierres', '5', Icons.handshake_outlined)),
              ],
            ),
            const SizedBox(height: 32),
            
            const Text('Herramientas CRM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            const SizedBox(height: 16),
            
            _buildToolTile(
              title: 'Contactos y Agenda',
              subtitle: 'Gestiona tus clientes y prospectos.',
              icon: Icons.contacts_outlined,
              onTap: () => context.push('/crm-contacts'),
            ),
            _buildToolTile(
              title: 'Embudo de Oportunidades',
              subtitle: 'Seguimiento visual de tus negocios.',
              icon: Icons.view_kanban_outlined,
              onTap: () => context.push('/crm-opportunities'),
            ),
            _buildToolTile(
              title: 'Cartera de Propiedades',
              subtitle: 'Tus inmuebles con métricas avanzadas.',
              icon: Icons.maps_home_work_outlined,
              onTap: () => context.push('/my-listings'), // Reusa my-listings pero en PRO
            ),
            _buildToolTile(
              title: 'Reportes y Analítica',
              subtitle: 'Mide tu rendimiento mensual.',
              icon: Icons.bar_chart_outlined,
              onTap: () => context.push('/basic-stats'), // Reusa basic stats por ahora
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: KazaTheme.primaryCoral, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: KazaTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildToolTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: KazaTheme.n100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: KazaTheme.azulKaza),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: KazaTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: KazaTheme.grisMedio),
        onTap: onTap,
      ),
    );
  }
}
