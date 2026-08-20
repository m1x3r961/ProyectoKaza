import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/financing_models.dart';
import 'handoff_dialog.dart';

class EntityDetailSheet extends StatelessWidget {
  final FinancialEntity entity;

  const EntityDetailSheet({super.key, required this.entity});

  void _onConnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => HandoffDialog(entity: entity),
    );
  }

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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: entity.brandColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.account_balance, color: entity.brandColor, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conectar con ${entity.name}', style: const TextStyle(color: KazaTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${entity.creditType} • ${entity.currency}', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Condiciones referenciales', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tasa referencial desde', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                Text('${entity.referenceRate.toStringAsFixed(2)}% anual', style: const TextStyle(color: KazaTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32, color: KazaTheme.glassBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Plazo máximo', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                Text('${entity.maxTermYears} años', style: const TextStyle(color: KazaTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32, color: KazaTheme.glassBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Moneda', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                Text(entity.currency, style: const TextStyle(color: KazaTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onConnect(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: entity.brandColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Conectar con ${entity.name}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
