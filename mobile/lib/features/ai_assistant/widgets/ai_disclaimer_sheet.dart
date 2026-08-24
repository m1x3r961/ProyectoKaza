import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';

class AiDisclaimerSheet extends StatelessWidget {
  const AiDisclaimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KazaTheme.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: KazaTheme.azulKaza),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Límites de KAZA Imagina',
                    style: TextStyle(color: KazaTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Imagina NO puede:',
              style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildLimitItem(Icons.cancel_outlined, 'Garantizar precios futuros'),
            _buildLimitItem(Icons.cancel_outlined, 'Predecir decisiones de personas'),
            _buildLimitItem(Icons.cancel_outlined, 'Detectar problemas legales ocultos'),
            _buildLimitItem(Icons.cancel_outlined, 'Sustituir inspección profesional'),
            _buildLimitItem(Icons.cancel_outlined, 'Sustituir asesoría legal o financiera'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KazaTheme.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KazaTheme.glassBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cuándo se abstiene', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                  SizedBox(height: 4),
                  Text('Si la información es insuficiente o de baja calidad, Imagina lo indicará claramente y no generará conclusiones.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13, height: 1.4)),
                  SizedBox(height: 16),
                  Text('Transparencia total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                  SizedBox(height: 4),
                  Text('Siempre podrás ver las fuentes, supuestos y nivel de confianza de cada análisis.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KazaTheme.azulKaza,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Entendido, continuar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: KazaTheme.coralKaza, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14))),
        ],
      ),
    );
  }
}
