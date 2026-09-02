import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';

/// 🏢 PANEL ORGANIZACIONAL (U07 BUSINESS)
class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Panel Organizacional', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: KazaTheme.azulKaza),
            onPressed: () {}, // Ajustes de la org
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de la organización
            Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_rounded, color: KazaTheme.azulKaza, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mi Inmobiliaria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
                      Text('Propietario', style: TextStyle(color: KazaTheme.coralKaza, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Métricas principales (Consolidadas)
            const Text('Vista general del negocio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Propiedades', '32', Icons.maps_home_work_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Vistas (30d)', '1.256', Icons.remove_red_eye_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Oportunidades', '402', Icons.filter_alt_outlined)),
              ],
            ),
            const SizedBox(height: 32),

            // Módulos U07
            const Text('Módulos de Negocio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            const SizedBox(height: 16),

            _buildToolTile(
              title: 'Miembros y Equipo',
              subtitle: 'Gestiona tu equipo y sus roles.',
              icon: Icons.people_outline,
              onTap: () => context.push('/org-members'),
            ),
            _buildToolTile(
              title: 'Propiedades',
              subtitle: 'Inventario completo y centralizado.',
              icon: Icons.home_work_outlined,
              onTap: () => context.push('/org-properties'),
            ),
            _buildToolTile(
              title: 'Oportunidades (Pipeline)',
              subtitle: 'Embudo consolidado del equipo.',
              icon: Icons.view_kanban_outlined,
              onTap: () => context.push('/org-opportunities'),
            ),
            _buildToolTile(
              title: 'Reportes y Dashboard',
              subtitle: 'KPIs y dashboards organizacionales.',
              icon: Icons.bar_chart_outlined,
              onTap: () {}, // Placeholder phase 3
            ),
            _buildToolTile(
              title: 'Marketing',
              subtitle: 'Campañas y presencia de marca.',
              icon: Icons.campaign_outlined,
              onTap: () {}, // Placeholder phase 3
            ),
            _buildToolTile(
              title: 'Integraciones',
              subtitle: 'Conecta y automatiza tus procesos.',
              icon: Icons.hub_outlined,
              onTap: () {}, // Placeholder phase 3
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
          Icon(icon, color: const Color(0xFF7C4DFF), size: 28), // Purple for business
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: KazaTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF7C4DFF)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: KazaTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: KazaTheme.grisMedio),
        onTap: onTap,
      ),
    );
  }
}
