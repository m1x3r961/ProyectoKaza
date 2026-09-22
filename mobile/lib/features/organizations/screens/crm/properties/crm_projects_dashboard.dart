import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/kaza_theme.dart';
import '../../../providers/crm_projects_provider.dart';
import 'crm_project_detail_screen.dart';
import '../../../models/project_model.dart';

class CrmProjectsDashboard extends ConsumerWidget {
  const CrmProjectsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(crmProjectsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: KazaTheme.azulKaza,
        title: const Text('KAZA Properties', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // TODO: Implement create project flow
            },
          )
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return _buildEmptyState();
          }

          int totalUnits = projects.fold(0, (sum, p) => sum + p.totalUnits);
          int soldUnits = projects.fold(0, (sum, p) => sum + p.soldUnits);
          double avgProgress = projects.isEmpty ? 0 : projects.fold(0.0, (sum, p) => sum + p.progressPct) / projects.length;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(crmProjectsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMetricsOverview(projects.length, totalUnits, soldUnits, avgProgress),
                const SizedBox(height: 24),
                const Text('Mis Proyectos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
                const SizedBox(height: 12),
                ...projects.map((p) => _buildProjectCard(context, p)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business_center_outlined, size: 64, color: KazaTheme.grisMedio),
          const SizedBox(height: 16),
          const Text('Sin proyectos aún', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Crea tu primer proyecto inmobiliario\npara empezar a gestionar unidades.', textAlign: TextAlign.center, style: TextStyle(color: KazaTheme.textMuted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Crear Proyecto', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: KazaTheme.coralKaza,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview(int activeProjects, int totalUnits, int soldUnits, double avgProgress) {
    return Row(
      children: [
        _MetricBox(title: 'Proyectos Activos', value: activeProjects.toString(), color: KazaTheme.azulKaza),
        const SizedBox(width: 12),
        _MetricBox(title: 'Unidades Vendidas', value: '$soldUnits / $totalUnits', color: Colors.green),
        const SizedBox(width: 12),
        _MetricBox(title: 'Avance Promedio', value: '${(avgProgress * 100).toInt()}%', color: KazaTheme.coralKaza),
      ],
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CrmProjectDetailScreen(project: project)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: KazaTheme.azulKaza,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(project.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
                    ),
                  ),
                  const Center(child: Icon(Icons.apartment_rounded, size: 48, color: Colors.white24)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: KazaTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(project.city ?? 'Ubicación no definida', style: const TextStyle(color: KazaTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn(label: 'Unidades', value: project.totalUnits.toString()),
                      _StatColumn(label: 'Disponibles', value: project.availableUnits.toString()),
                      _StatColumn(label: 'Vendidas', value: project.soldUnits.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricBox({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: KazaTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.textMuted)),
      ],
    );
  }
}
