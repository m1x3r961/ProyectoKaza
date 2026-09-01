import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';

/// ⚖️ COMPARE TAB SCREEN — "14 GUARDADOS Y COMPARAR"
/// Landing page for the Compare tab. Shows saved properties
/// and allows selecting 2-3 to compare side by side.
class CompareTabScreen extends ConsumerWidget {
  const CompareTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Comparar',
          style: TextStyle(
            color: KazaTheme.azulKaza,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: KazaTheme.n000,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  size: 48,
                  color: KazaTheme.azulKaza,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Compara hasta 3 propiedades\nen paralelo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.azulKaza,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Guarda propiedades desde el mapa y\nselecciona las que deseas comparar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KazaTheme.grisMedio,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KazaTheme.n100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: KazaTheme.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Límite Plan Free: Máx. 3 propiedades',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KazaTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KazaTheme.azulKaza,
                    side: const BorderSide(color: KazaTheme.azulKaza),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Navigate to comparar flow — placeholder
                  },
                  icon: const Icon(Icons.compare_arrows_rounded, size: 20),
                  label: const Text(
                    'Ver comparador',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
