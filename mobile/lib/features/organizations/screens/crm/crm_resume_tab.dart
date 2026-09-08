import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/kaza_theme.dart';
import '../../providers/crm_stats_provider.dart';

class CrmResumeTab extends ConsumerWidget {
  const CrmResumeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(crmStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: statsAsync.when(
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text('No se encontró información de la organización.'));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(stats.orgName),
              const SizedBox(height: 24),
              _buildMainMetrics(stats.propertiesCount.toString(), stats.totalViews.toString(), '0'), // Programadas no están mapeadas aún
              const SizedBox(height: 32),
              _buildPipelineOportunidades(),
              const SizedBox(height: 32),
              _buildCrecimiento(stats.totalViews.toString()),
              const SizedBox(height: 32),
              _buildEntorno(stats.membersCount.toString()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeader(String orgName) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: KazaTheme.azulKaza,
            shape: BoxShape.circle,
            border: Border.all(color: KazaTheme.coralKaza, width: 2),
          ),
          child: const Icon(Icons.architecture, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orgName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary),
              ),
              const Row(
                children: [
                  Text('Business ', style: TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
                  Icon(Icons.circle, color: Colors.green, size: 8),
                  Text(' Active', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainMetrics(String props, String views, String programadas) {
    return Row(
      children: [
        Expanded(child: _buildMetricItem(props, 'Propiedades')),
        Container(width: 1, height: 40, color: Colors.grey.shade200),
        Expanded(child: _buildMetricItem(views, 'Vistas (30d)')),
        Container(width: 1, height: 40, color: Colors.grey.shade200),
        Expanded(child: _buildMetricItem(programadas, 'Programadas')),
      ],
    );
  }

  Widget _buildMetricItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
        Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPipelineOportunidades() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pipeline de oportunidades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
            Text('Este mes >', style: TextStyle(fontSize: 12, color: KazaTheme.primaryCoral, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        // Placeholder for progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [KazaTheme.azulKaza, Colors.blue, Colors.orange, KazaTheme.primaryCoral, Colors.green],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _pipelineStat('52', 'Nuevos'),
            _pipelineStat('64', 'Contactados'),
            _pipelineStat('38', 'Visitas'),
            _pipelineStat('16', 'Propuestas'),
            _pipelineStat('8', 'Cerrados'),
          ],
        ),
      ],
    );
  }

  Widget _pipelineStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: KazaTheme.textMuted)),
      ],
    );
  }

  Widget _buildCrecimiento(String views) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Crecimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            Text('Últimos 30 días >', style: TextStyle(fontSize: 12, color: KazaTheme.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildCrecimientoCard('Impresiones', '24.6K', '+12%', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildCrecimientoCard('Leads', '8.4K', '+5%', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildCrecimientoCard('Vistas', views, '+15%', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildCrecimientoCard('Tasa Conversión', '3.1%', '+0.4 pp', true)),
          ],
        )
      ],
    );
  }

  Widget _buildCrecimientoCard(String label, String val, String varPct, bool positive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: KazaTheme.textMuted, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(varPct, style: TextStyle(fontSize: 10, color: positive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEntorno(String membersCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Entorno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            Text('Evaluación >', style: TextStyle(fontSize: 12, color: KazaTheme.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildEntornoItem(membersCount, 'Miembros'),
            _buildEntornoItem('4', 'Equipos'),
            _buildEntornoItem('2', 'Sucursales'),
            _buildEntornoItem('2', 'Invitaciones'),
          ],
        )
      ],
    );
  }

  Widget _buildEntornoItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: KazaTheme.azulKaza)),
        Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.textMuted)),
      ],
    );
  }
}
