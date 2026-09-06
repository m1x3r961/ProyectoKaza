import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/developer_models.dart';
import '../providers/developer_provider.dart';

/// 🏗️ PANEL DESARROLLADORA (U08)
class DeveloperDashboardScreen extends ConsumerStatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  ConsumerState<DeveloperDashboardScreen> createState() => _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends ConsumerState<DeveloperDashboardScreen> {
  bool _seedLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = ref.read(kazaAuthProvider).userId;
    if (userId != null) {
      await ref.read(developerProvider.notifier).loadAll(userId);
    }
  }

  Future<void> _seedAndReload() async {
    setState(() => _seedLoading = true);
    final success = await ref.read(developerProvider.notifier).seedDemoData();
    if (success) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Datos de ejemplo cargados exitosamente'), backgroundColor: KazaTheme.verifiedGreen),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ No se pudieron cargar datos de ejemplo'), backgroundColor: KazaTheme.semanticError),
        );
      }
    }
    setState(() => _seedLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final devState = ref.watch(developerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Desarrolladora', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          if (devState.projects.isEmpty && !devState.isLoading)
            TextButton.icon(
              onPressed: _seedLoading ? null : _seedAndReload,
              icon: _seedLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded, size: 18),
              label: const Text('Cargar demo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: devState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : devState.projects.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Perfil profesional
                      if (devState.profile != null) _buildProfileHeader(devState.profile!),
                      const SizedBox(height: 20),

                      // Métricas globales
                      _buildGlobalMetrics(devState),
                      const SizedBox(height: 24),

                      // Lista de proyectos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mis Proyectos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: KazaTheme.textPrimary)),
                          Text('${devState.totalProjects} proyecto(s)', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...devState.projects.map((p) => _buildProjectCard(p)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 64, color: KazaTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Sin proyectos aún', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: KazaTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Carga los datos de ejemplo para explorar el módulo Desarrolladora completo.', textAlign: TextAlign.center, style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _seedLoading ? null : _seedAndReload,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Cargar datos de ejemplo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfessionalProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: KazaTheme.grisClaro, child: const Icon(Icons.construction, color: KazaTheme.coralKaza)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.companyName ?? 'Mi Empresa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
                Text(profile.specialty ?? 'Desarrolladora', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: KazaTheme.accentGold, size: 16),
                  const SizedBox(width: 4),
                  Text('${profile.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                ],
              ),
              Text('(${profile.totalReviews})', style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalMetrics(DeveloperState devState) {
    return Row(
      children: [
        Expanded(child: _buildMetric('Proyectos\nactivos', '${devState.activeProjects}', KazaTheme.azulKaza)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetric('Unidades\nvendidas', '${devState.totalUnitsSold}', KazaTheme.verifiedGreen)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetric('Avance\nventas', '${devState.overallSalesPct.toStringAsFixed(1)}%', KazaTheme.coralKaza)),
      ],
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(DevProject project) {
    final statusColor = _statusColor(project.status);
    return GestureDetector(
      onTap: () => context.push('/project-detail', extra: project),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KazaTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(project.statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${project.projectType} • ${project.city ?? ""}', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            // Barra de progreso
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progressPct / 100,
                      backgroundColor: KazaTheme.glassBorder,
                      color: statusColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${project.progressPct.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: statusColor)),
              ],
            ),
            const SizedBox(height: 12),
            // Métricas inline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInlineMetric(Icons.apartment, '${project.totalUnits} uds'),
                _buildInlineMetric(Icons.check_circle_outline, '${project.soldUnits} vendidas', color: KazaTheme.verifiedGreen),
                _buildInlineMetric(Icons.schedule, '${project.reservedUnits} reservadas', color: KazaTheme.statusReserved),
                _buildInlineMetric(Icons.storefront, '${project.availableUnits} disponibles'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineMetric(IconData icon, String text, {Color color = KazaTheme.textSecondary}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CONSTRUCCION': return KazaTheme.coralKaza;
      case 'COMERCIALIZACION': return KazaTheme.verifiedGreen;
      case 'ENTREGA': return KazaTheme.azulKaza;
      case 'PLANIFICACION': return KazaTheme.semanticInfo;
      case 'LEGALIZACION': return KazaTheme.semanticWarning;
      case 'POST_VENTA': return KazaTheme.textSecondary;
      default: return KazaTheme.textMuted;
    }
  }
}
