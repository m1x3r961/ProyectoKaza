import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class ComparatorScreen extends StatelessWidget {
  final Map<String, dynamic> prop1;
  final Map<String, dynamic> prop2;

  const ComparatorScreen({
    super.key,
    required this.prop1,
    required this.prop2,
  });

  String _formatPrice(Map<String, dynamic> prop) {
    final priceUsd = prop['price_usd'];
    final priceBob = prop['price_bob'];
    
    if (priceUsd != null && priceUsd > 0) return 'USD ${priceUsd.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    if (priceBob != null && priceBob > 0) return 'Bs ${priceBob.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    return 'Consultar precio';
  }

  String _getPricePerM2(Map<String, dynamic> prop) {
    final priceUsd = prop['price_usd'];
    final priceBob = prop['price_bob'];
    final surface = prop['total_surface_m2'] ?? 0;

    if (surface == 0) return '—';

    if (priceUsd != null && priceUsd > 0) {
      final pm2 = (priceUsd / surface).round();
      return 'USD ${pm2.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }
    if (priceBob != null && priceBob > 0) {
      final pm2 = (priceBob / surface).round();
      return 'Bs ${pm2.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }
    return '—';
  }

  String _getZone(Map<String, dynamic> prop) {
    final address = prop['address_canonical']?.toString() ?? '';
    final parts = address.split('·');
    if (parts.length > 1) {
      return parts.last.trim();
    }
    return address.isNotEmpty ? address : 'Propiedad';
  }

  Widget _buildRow(String label, String val1, String val2) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: KazaTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  val1,
                  style: const TextStyle(
                    color: KazaTheme.azulKaza,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  val2,
                  style: const TextStyle(
                    color: KazaTheme.azulKaza,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final op = prop1['operation']?.toString().capitalize() ?? 'Venta';
    final type = prop1['property_type']?.toString().capitalize() ?? 'Propiedad';

    final surface1 = prop1['total_surface_m2'] ?? 0;
    final surface2 = prop2['total_surface_m2'] ?? 0;

    final rooms1 = prop1['rooms'] ?? 0;
    final rooms2 = prop2['rooms'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KazaTheme.azulKaza),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Comparar',
                style: TextStyle(
                  color: KazaTheme.azulKaza,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$op · $type · 2 propiedades',
                style: const TextStyle(
                  color: KazaTheme.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),

              // Images
              Row(
                children: [
                  const Expanded(flex: 2, child: SizedBox()), // Label space
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title & Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 2, child: SizedBox()),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getZone(prop1),
                          style: const TextStyle(
                            color: KazaTheme.azulKaza,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(prop1),
                          style: const TextStyle(
                            color: KazaTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getZone(prop2),
                          style: const TextStyle(
                            color: KazaTheme.azulKaza,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(prop2),
                          style: const TextStyle(
                            color: KazaTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Table
              _buildRow('Construido', surface1 > 0 ? '$surface1 m²' : 'No informado', surface2 > 0 ? '$surface2 m²' : 'No informado'),
              _buildRow('Precio/m²', _getPricePerM2(prop1), _getPricePerM2(prop2)),
              _buildRow('Dormitorios', rooms1 > 0 ? rooms1.toString() : '—', rooms2 > 0 ? rooms2.toString() : '—'),
              _buildRow('Antigüedad', prop1['antiquity']?.toString() ?? 'No informado', prop2['antiquity']?.toString() ?? 'No informado'),

              const SizedBox(height: 16),
              const Text(
                'KAZA no inventa precio ni precio/m².',
                style: TextStyle(
                  color: KazaTheme.textMuted,
                  fontSize: 11,
                ),
              ),

              const Spacer(),
              
              // Action Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La IA de KAZA pronto te ayudará a comparar.'),
                        backgroundColor: KazaTheme.azulKaza,
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Ayúdame a comparar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KazaTheme.azulKaza,
                    side: const BorderSide(color: KazaTheme.azulKaza),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
