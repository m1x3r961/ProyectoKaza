import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';

/// 📊 ESTADÍSTICAS BÁSICAS (U05 PLUS)
class BasicStatsScreen extends StatelessWidget {
  const BasicStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Rendimiento', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Últimos 30 días',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard('Vistas', '1.256', '+15%', true)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Contactos', '48', '+5%', true)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Guardados', '120', '-2%', false)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Compartidos', '35', '+10%', true)),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Propiedad más vista',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KazaTheme.glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: KazaTheme.grisClaro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: KazaTheme.grisMedio),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Departamento Equipetrol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('845 vistas esta semana', style: TextStyle(color: KazaTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String trend, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: KazaTheme.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? KazaTheme.verifiedGreen : KazaTheme.semanticError,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: isPositive ? KazaTheme.verifiedGreen : KazaTheme.semanticError,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
