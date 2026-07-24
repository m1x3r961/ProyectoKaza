import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_badges.dart';

/// 🔖 GUARDADOS Y LISTAS - Kaza Saved & Comparator
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text('Mis Listas & Guardados'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KazaTheme.primaryTealLight,
          labelColor: KazaTheme.primaryTealLight,
          unselectedLabelColor: KazaTheme.textMuted,
          tabs: const [
            Tab(text: 'Venta (2)'),
            Tab(text: 'Alquiler (1)'),
            Tab(text: 'Comparador'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Guardados Venta
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSavedCard(
                title: 'Departamento Ejecutivo Equipetrol',
                price: '\$ 128,000',
                surface: '85 m²',
                rooms: '2 dorms',
                location: 'Equipetrol Norte, Santa Cruz',
                isPlus: true,
              ),
              const SizedBox(height: 12),
              _buildSavedCard(
                title: 'Casa Moderna en Urubó West',
                price: '\$ 340,000',
                surface: '320 m²',
                rooms: '4 dorms',
                location: 'Urubó, Porongo',
                isPlus: true,
              ),
            ],
          ),

          // 2. Guardados Alquiler
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSavedCard(
                title: 'Oficina Comercial Sirari',
                price: '\$ 950 / mes',
                surface: '50 m²',
                rooms: '1 ambiente',
                location: 'Sirari, Santa Cruz',
                isPlus: false,
              ),
            ],
          ),

          // 3. Comparador de Inmuebles
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comparación de Propiedades (Venta)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'El comparador solo enfrenta cohortes de la misma operación para ofrecer métricas precisas.',
                  style: TextStyle(color: KazaTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildComparisonColumn(
                          title: 'Departamento Equipetrol',
                          price: '\$ 128,000',
                          priceM2: '\$ 1,505 / m²',
                          surface: '85 m²',
                          rooms: '2',
                          bathrooms: '2',
                          dom: '14 días en mercado',
                        ),
                        const SizedBox(width: 16),
                        _buildComparisonColumn(
                          title: 'Casa Urubó West',
                          price: '\$ 340,000',
                          priceM2: '\$ 1,062 / m²',
                          surface: '320 m²',
                          rooms: '4',
                          bathrooms: '4',
                          dom: '42 días en mercado',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCard({
    required String title,
    required String price,
    required String surface,
    required String rooms,
    required String location,
    required bool isPlus,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apartment, color: Colors.white54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPlus) const KazaPlusBadge(),
                      const Spacer(),
                      const Icon(Icons.bookmark, color: KazaTheme.primaryTealLight, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(location, style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(price, style: const TextStyle(color: KazaTheme.primaryTealLight, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonColumn({
    required String title,
    required String price,
    required String priceM2,
    required String surface,
    required String rooms,
    required String bathrooms,
    required String dom,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KazaTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(price, style: const TextStyle(color: KazaTheme.primaryTealLight, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(priceM2, style: const TextStyle(color: KazaTheme.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
          const Divider(height: 24, color: KazaTheme.glassBorder),
          _compRow('Superficie', surface),
          _compRow('Dormitorios', rooms),
          _compRow('Baños', bathrooms),
          _compRow('Días Mercado', dom),
        ],
      ),
    );
  }

  Widget _compRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
