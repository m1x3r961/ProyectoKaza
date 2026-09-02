import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

/// 🏠 PROPIEDADES (U07 BUSINESS) - Inventario consolidado
class OrgPropertiesScreen extends StatelessWidget {
  const OrgPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Inventario Organizacional', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: KazaTheme.textSecondary), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildPropertyCard('Casa en Venta - Equipetrol', 'Bs 250.000', 'Activa', 'Juan Pérez'),
          const SizedBox(height: 16),
          _buildPropertyCard('Oficina Central - Urubó', 'Bs 180.000', 'En negociación', 'Lucía Ruiz'),
          const SizedBox(height: 16),
          _buildPropertyCard('Departamento 2 Dorm - Centro', 'Bs 95.000', 'Activa', 'María Silva'),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(String title, String price, String status, String agent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: KazaTheme.grisClaro,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(child: Icon(Icons.image, color: KazaTheme.grisMedio, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Agente: $agent', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'Activa' ? KazaTheme.verifiedGreen.withValues(alpha: 0.1) : KazaTheme.accentGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status, style: TextStyle(color: status == 'Activa' ? KazaTheme.verifiedGreen : KazaTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
