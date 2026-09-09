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
  String? _getImage(Map<String, dynamic> prop) {
    if (prop['photos'] != null && prop['photos'] is List && (prop['photos'] as List).isNotEmpty) {
      return prop['photos'][0].toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final op = prop1['operation']?.toString().capitalize() ?? 'Venta';
    final type = prop1['property_type']?.toString().capitalize() ?? 'Propiedad';

    final surface1 = prop1['total_surface_m2'] ?? 0;
    final surface2 = prop2['total_surface_m2'] ?? 0;

    final rooms1 = prop1['rooms'] ?? 0;
    final rooms2 = prop2['rooms'] ?? 0;

    final baths1 = prop1['bathrooms'] ?? 0;
    final baths2 = prop2['bathrooms'] ?? 0;

    final parking1 = prop1['parking'] ?? 0;
    final parking2 = prop2['parking'] ?? 0;

    final img1 = _getImage(prop1);
    final img2 = _getImage(prop2);

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
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(12),
                        image: img1 != null ? DecorationImage(image: NetworkImage(img1), fit: BoxFit.cover) : null,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: img1 == null ? const Icon(Icons.image, color: Colors.black12, size: 32) : null,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(12),
                        image: img2 != null ? DecorationImage(image: NetworkImage(img2), fit: BoxFit.cover) : null,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: img2 == null ? const Icon(Icons.image, color: Colors.black12, size: 32) : null,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: KazaTheme.azulKaza,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: KazaTheme.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatPrice(prop1),
                            style: const TextStyle(
                              color: KazaTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: KazaTheme.azulKaza,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: KazaTheme.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatPrice(prop2),
                            style: const TextStyle(
                              color: KazaTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
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
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildRow('Construido', surface1 > 0 ? '$surface1 m²' : 'No info', surface2 > 0 ? '$surface2 m²' : 'No info'),
                    _buildRow('Precio/m²', _getPricePerM2(prop1), _getPricePerM2(prop2)),
                    _buildRow('Dormitorios', rooms1 > 0 ? rooms1.toString() : '—', rooms2 > 0 ? rooms2.toString() : '—'),
                    _buildRow('Baños', baths1 > 0 ? baths1.toString() : '—', baths2 > 0 ? baths2.toString() : '—'),
                    _buildRow('Parqueos', parking1 > 0 ? parking1.toString() : '—', parking2 > 0 ? parking2.toString() : '—'),
                    _buildRow('Antigüedad', prop1['antiquity']?.toString().capitalize() ?? 'No info', prop2['antiquity']?.toString().capitalize() ?? 'No info'),
                    _buildRow('Estado', prop1['condition']?.toString().capitalize() ?? '—', prop2['condition']?.toString().capitalize() ?? '—'),
                    _buildRow('Ubicación exacta', prop1['address_canonical']?.toString() ?? '—', prop2['address_canonical']?.toString() ?? '—'),
                    
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'KAZA no inventa precio ni precio/m².',
                        style: TextStyle(
                          color: KazaTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              
              // Action Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24, top: 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La IA de KAZA pronto te ayudará a comparar y decidir.'),
                        backgroundColor: KazaTheme.azulKaza,
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Ayúdame a decidir'),
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
