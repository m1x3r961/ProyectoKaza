import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/listing_model.dart';
import '../providers/my_listings_provider.dart';

/// 🏠 MIS PUBLICACIONES v0.3 FINAL (Gestión de Inmuebles Real)
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  String _selectedTab = 'Todas'; // Todas, Activas, Pausadas, Borradores

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Mis publicaciones', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: KazaTheme.textPrimary),
      ),
      body: Column(
        children: [
          // Filtros / Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _buildTabPill('Todas'),
                const SizedBox(width: 8),
                _buildTabPill('Activas'),
                const SizedBox(width: 8),
                _buildTabPill('Pausadas'),
                const SizedBox(width: 8),
                _buildTabPill('Borradores'),
              ],
            ),
          ),
          const Divider(color: KazaTheme.glassBorder, height: 1),

          // Lista de inmuebles desde Supabase
          Expanded(
            child: listingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
              data: (listings) {
                // Filtrar según el tab seleccionado
                final filteredListings = listings.where((listing) {
                  if (_selectedTab == 'Todas') return true;
                  if (_selectedTab == 'Activas') return listing.status == 'AVAILABLE' || listing.status == 'PUBLISHED';
                  if (_selectedTab == 'Pausadas') return listing.status == 'PAUSED';
                  if (_selectedTab == 'Borradores') return listing.status == 'DRAFT';
                  return true;
                }).toList();

                if (filteredListings.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron publicaciones en este estado.', style: TextStyle(color: KazaTheme.textMuted)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredListings.length,
                  itemBuilder: (context, index) {
                    final listing = filteredListings[index];
                    return _buildPropertyCard(listing);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String title) {
    final isSelected = _selectedTab == title;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.redAccent : KazaTheme.glassBorder, width: isSelected ? 1.5 : 1.0),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.redAccent : KazaTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(ListingModel listing) {
    // Determinar UI según el estado real
    String displayStatus = listing.status;
    Color statusColor = KazaTheme.textMuted;
    List<String> actions = [];

    switch (listing.status) {
      case 'AVAILABLE':
      case 'PUBLISHED':
        displayStatus = 'ACTIVO';
        statusColor = KazaTheme.statusAvailable;
        actions = ['Actualizar disponibilidad', 'Pausar', 'Editar', 'Retirar'];
        break;
      case 'PAUSED':
        displayStatus = 'PAUSADO';
        statusColor = KazaTheme.statusPaused;
        actions = ['Reactivar', 'Editar', 'Retirar'];
        break;
      case 'RESERVED':
        displayStatus = 'RESERVADO';
        statusColor = KazaTheme.statusReserved;
        actions = ['Marcar disponible', 'Cerrar operación', 'Editar'];
        break;
      case 'DRAFT':
        displayStatus = 'DRAFT';
        statusColor = KazaTheme.textMuted;
        actions = ['Continuar borrador', 'Eliminar borrador'];
        break;
      case 'CLOSED':
        displayStatus = 'CERRADO';
        statusColor = KazaTheme.statusClosed;
        actions = ['Ver historial'];
        break;
      case 'WITHDRAWN':
        displayStatus = 'RETIRADO';
        statusColor = KazaTheme.textMuted;
        actions = ['Ver historial', 'Republicar'];
        break;
    }

    final isDraft = listing.status == 'DRAFT';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder Imagen
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: KazaTheme.grisClaro,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('KAZA', style: TextStyle(color: KazaTheme.grisMedio, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 16),
                // Datos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(listing.formattedPrice, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDraft ? KazaTheme.textMuted : KazaTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(displayStatus, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: KazaTheme.glassBorder, height: 1),
          // Botones de Acción
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((actionName) {
                final isPrimaryAction = actionName == 'Actualizar disponibilidad' || actionName == 'Continuar borrador' || actionName == 'Reactivar' || actionName == 'Marcar disponible';
                return OutlinedButton(
                  onPressed: () => _handleAction(actionName, listing),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: BorderSide(color: isPrimaryAction ? Colors.redAccent : KazaTheme.glassBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    actionName,
                    style: TextStyle(
                      color: isPrimaryAction ? Colors.redAccent : KazaTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: isPrimaryAction ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, ListingModel listing) {
    final notifier = ref.read(myListingsProvider.notifier);
    
    switch (action) {
      case 'Actualizar disponibilidad':
        notifier.refreshAvailability(listing.id);
        break;
      case 'Pausar':
        notifier.updateStatus(listing.id, 'PAUSED');
        break;
      case 'Reactivar':
      case 'Marcar disponible':
      case 'Republicar':
        notifier.updateStatus(listing.id, 'PUBLISHED');
        break;
      case 'Retirar':
        notifier.updateStatus(listing.id, 'WITHDRAWN');
        break;
      case 'Cerrar operación':
        notifier.updateStatus(listing.id, 'CLOSED');
        break;
      case 'Eliminar borrador':
        // Not implemented yet, usually an ARCHIVED status or physical DELETE
        notifier.updateStatus(listing.id, 'ARCHIVED');
        break;
      case 'Editar':
      case 'Continuar borrador':
      case 'Ver historial':
        // These would navigate to other screens
        break;
    }
  }
}
