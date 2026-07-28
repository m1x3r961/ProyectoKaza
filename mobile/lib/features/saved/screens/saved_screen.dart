import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import 'comparator_screen.dart';

final savedPropertiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseConfig.client
      .from('saved_properties')
      .select('*, properties(*)');
  return List<Map<String, dynamic>>.from(response);
});

/// 🔖 GUARDADOS - WM-02 v0.3
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {


  void _onComparePressed(List<Map<String, dynamic>> savedItems) {
    if (savedItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos 2 propiedades para comparar.'),
          backgroundColor: KazaTheme.primaryCoral,
        ),
      );
      return;
    }

    // Regla V1: comparación cuantitativa principal = misma operación + misma tipología.
    // Buscamos 2 propiedades que coincidan en operacion y tipologia
    Map<String, dynamic>? p1;
    Map<String, dynamic>? p2;

    for (int i = 0; i < savedItems.length; i++) {
      final prop1 = savedItems[i]['properties'] as Map<String, dynamic>?;
      if (prop1 == null) continue;
      
      final op1 = prop1['operation']?.toString().toUpperCase();
      final type1 = prop1['property_type']?.toString().toUpperCase();

      for (int j = i + 1; j < savedItems.length; j++) {
        final prop2 = savedItems[j]['properties'] as Map<String, dynamic>?;
        if (prop2 == null) continue;

        final op2 = prop2['operation']?.toString().toUpperCase();
        final type2 = prop2['property_type']?.toString().toUpperCase();

        if (op1 == op2 && type1 == type2) {
          p1 = prop1;
          p2 = prop2;
          break;
        }
      }
      if (p1 != null) break;
    }

    if (p1 != null && p2 != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComparatorScreen(prop1: p1!, prop2: p2!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay 2 propiedades guardadas de la misma operación y tipología para comparar (V1).'),
          backgroundColor: KazaTheme.accentGold,
        ),
      );
    }
  }

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
      return 'USD $pm2/m²';
    }
    if (priceBob != null && priceBob > 0) {
      final pm2 = (priceBob / surface).round();
      return 'Bs $pm2/m²';
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final savedAsyncValue = ref.watch(savedPropertiesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Guardados',
          style: TextStyle(
            color: KazaTheme.azulKaza,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          savedAsyncValue.when(
            data: (items) => TextButton(
              onPressed: () => _onComparePressed(items),
              child: const Text(
                'Comparar',
                style: TextStyle(
                  color: KazaTheme.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: savedAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: KazaTheme.azulKaza)),
        error: (err, stack) => _buildEmptySavedState(),
        data: (savedItems) {
          if (savedItems.isEmpty) return _buildEmptySavedState();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(savedPropertiesProvider);
            },
            child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: savedItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = savedItems[index];
                    final prop = item['properties'] as Map<String, dynamic>? ?? {};

                    final title = prop['address_canonical'] ?? 'Inmueble Guardado';
                    final priceStr = _formatPrice(prop);
                    final surface = prop['total_surface_m2'] ?? 0;
                    final priceM2Str = _getPricePerM2(prop);
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Image Placeholder
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.black12, size: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: KazaTheme.azulKaza,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                priceStr,
                                style: const TextStyle(
                                  color: KazaTheme.azulKaza,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                surface > 0 ? '$surface m² - $priceM2Str' : 'Superficie: No informado',
                                style: const TextStyle(
                                  color: KazaTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
          );
        }
      ),
    );
  }

  Widget _buildEmptySavedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: KazaTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No tienes guardados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explora el mapa y guarda propiedades.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
