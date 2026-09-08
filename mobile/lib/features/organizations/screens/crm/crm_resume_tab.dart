import 'package:flutter/material.dart';
import '../../../../app/theme/kaza_theme.dart';

class CrmResumeTab extends StatelessWidget {
  const CrmResumeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMainMetrics(),
          const SizedBox(height: 32),
          _buildPipelineOportunidades(),
          const SizedBox(height: 32),
          _buildCrecimiento(),
          const SizedBox(height: 32),
          _buildEntorno(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HIGA Arquitectura Estratégica',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary),
              ),
              Row(
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

  Widget _buildMainMetrics() {
    return Row(
      children: [
        Expanded(child: _buildMetricItem('128', 'Propiedades')),
        Container(width: 1, height: 40, color: Colors.grey.shade200),
        Expanded(child: _buildMetricItem('256', 'Vistas (30d)')),
        Container(width: 1, height: 40, color: Colors.grey.shade200),
        Expanded(child: _buildMetricItem('48', 'Programadas')),
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

  Widget _buildCrecimiento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Crecimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
            Text('Últimos 30 días >', style: TextStyle(fontSize: 12, color: KazaTheme.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _growthCard('Impresiones', '24.6K', '+12%')),
            const SizedBox(width: 12),
            Expanded(child: _growthCard('Leads', '8.4K', '+5%')),
            const SizedBox(width: 12),
            Expanded(child: _growthCard('Vistas', '298', '+15%')),
            const SizedBox(width: 12),
            Expanded(child: _growthCard('Tasa Conversión', '3.1%', '+0.4 pp')),
          ],
        ),
      ],
    );
  }

  Widget _growthCard(String title, String val, String grow) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 9, color: KazaTheme.textMuted), textAlign: TextAlign.center, maxLines: 1),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
          const SizedBox(height: 2),
          Text(grow, style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEntorno() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Entorno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
            Text('Evaluación >', style: TextStyle(fontSize: 12, color: KazaTheme.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _entornoStat('14', 'Miembros'),
            _entornoStat('4', 'Equipos'),
            _entornoStat('2', 'Sucursales'),
            _entornoStat('2', 'Invitaciones'),
          ],
        ),
      ],
    );
  }

  Widget _entornoStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: KazaTheme.azulKaza)),
        Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.textMuted)),
      ],
    );
  }
}
