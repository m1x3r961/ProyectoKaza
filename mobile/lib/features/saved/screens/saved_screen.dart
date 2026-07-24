import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/widgets/kaza_badges.dart';

/// 🔖 GUARDADOS Y LISTAS - Kaza Saved & Comparator
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _savedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSavedProperties();
  }

  Future<void> _fetchSavedProperties() async {
    try {
      final response = await SupabaseConfig.client
          .from('saved_properties')
          .select('*, properties(*)');
      if (mounted) {
        setState(() {
          _savedItems = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedItems = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ventaItems = _savedItems.where((i) => i['operation'] != 'ALQUILER').toList();
    final alquilerItems = _savedItems.where((i) => i['operation'] == 'ALQUILER').toList();

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
          tabs: [
            Tab(text: 'Venta (${ventaItems.length})'),
            Tab(text: 'Alquiler (${alquilerItems.length})'),
            const Tab(text: 'Comparador'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Guardados Venta
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ventaItems.isEmpty
                  ? _buildEmptySavedState('Venta')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ventaItems.length,
                      itemBuilder: (context, index) {
                        final item = ventaItems[index];
                        return _buildSavedCard(
                          title: item['title'] ?? 'Inmueble Guardado',
                          price: item['price'] ?? '\$ 0',
                          surface: item['surface'] ?? '0 m²',
                          rooms: item['rooms'] ?? '0 dorms',
                          location: item['location'] ?? 'Santa Cruz',
                          isPlus: true,
                        );
                      },
                    ),

          // 2. Guardados Alquiler
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : alquilerItems.isEmpty
                  ? _buildEmptySavedState('Alquiler')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alquilerItems.length,
                      itemBuilder: (context, index) {
                        final item = alquilerItems[index];
                        return _buildSavedCard(
                          title: item['title'] ?? 'Alquiler Guardado',
                          price: item['price'] ?? '\$ 0',
                          surface: item['surface'] ?? '0 m²',
                          rooms: item['rooms'] ?? '0 dorms',
                          location: item['location'] ?? 'Santa Cruz',
                          isPlus: false,
                        );
                      },
                    ),

          // 3. Comparador de Inmuebles
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.compare_arrows, size: 64, color: KazaTheme.primaryTealLight),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin propiedades para comparar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Guarda 2 o más propiedades de la misma modalidad para analizar su precio por m², días en mercado y características lado a lado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySavedState(String category) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: KazaTheme.primaryTealLight),
            const SizedBox(height: 16),
            Text(
              'No tienes guardados en $category',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explora el mapa y presiona el ícono 🔖 en tus inmuebles favoritos para conservarlos en tu lista personalizada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
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
