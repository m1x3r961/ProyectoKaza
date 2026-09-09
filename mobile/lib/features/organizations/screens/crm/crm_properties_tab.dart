import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/kaza_theme.dart';
import '../../../profile/models/listing_model.dart';
import '../../providers/crm_properties_provider.dart';

class CrmPropertiesTab extends ConsumerWidget {
  const CrmPropertiesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(crmPropertiesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(crmPropertiesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildPropertyCard(properties[index], context);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: KazaTheme.textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(crmPropertiesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 64, color: KazaTheme.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No hay propiedades en la organización',
            style: TextStyle(fontSize: 16, color: KazaTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las propiedades que publiques se mostrarán aquí.',
            style: TextStyle(color: KazaTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(ListingModel listing, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.grisClaro),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de portada
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Container(
                color: KazaTheme.grisClaro,
                child: const Icon(Icons.home, size: 48, color: KazaTheme.textMuted),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y Precio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        listing.title.isNotEmpty ? listing.title : 'Propiedad sin título',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      listing.formattedPrice,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                
                // Estado y Vistas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: listing.status == 'PUBLISHED' 
                            ? KazaTheme.coralKaza.withOpacity(0.1) 
                            : KazaTheme.grisClaro,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        listing.status == 'PUBLISHED' ? 'Activa' : 'Borrador',
                        style: TextStyle(
                          color: listing.status == 'PUBLISHED' ? KazaTheme.coralKaza : KazaTheme.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      listing.freshnessConfirmedAt != null ? 'Última act: ${listing.freshnessConfirmedAt!.toLocal().toString().split(' ')[0]}' : 'Última act: N/A',
                      style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12),
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
