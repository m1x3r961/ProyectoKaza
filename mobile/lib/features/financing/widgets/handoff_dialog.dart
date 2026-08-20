import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/financing_models.dart';

class HandoffDialog extends StatelessWidget {
  final FinancialEntity entity;

  const HandoffDialog({super.key, required this.entity});

  void _onConfirm(BuildContext context) {
    // Aquí iría la redirección web/deeplink. Por ahora, cerramos los modales.
    context.pop(); // Close dialog
    context.pop(); // Close sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redirigiendo a ${entity.name}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirmas salida',
              style: TextStyle(color: KazaTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Vas a salir de KAZA para continuar en el sitio oficial de ${entity.name}.',
              style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KazaTheme.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Al continuar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KazaTheme.textPrimary)),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: KazaTheme.azulKaza, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text('Compartiremos la información necesaria para la conexión.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: KazaTheme.azulKaza, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text('La evaluación y aprobación son 100% de la entidad.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onConfirm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KazaTheme.azulKaza,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continuar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancelar', style: TextStyle(color: KazaTheme.textSecondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
