import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';

/// 🏠 MIS PUBLICACIONES v0.3 FINAL (Gestión de Inmuebles)
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  String _selectedTab = 'Todas'; // Todas, Activas, Pausadas, Borradores

  @override
  Widget build(BuildContext context) {
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

          // Lista de inmuebles
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildPropertyCard(
                  title: 'Casa contemporánea con jardín',
                  price: '\$us 450.000',
                  status: 'ACTIVO',
                  statusColor: KazaTheme.statusAvailable,
                  actions: ['Actualizar disponibilidad', 'Pausar', 'Editar'],
                ),
                _buildPropertyCard(
                  title: 'Departamento con terraza',
                  price: 'USD 120.000',
                  status: 'RESERVADO',
                  statusColor: KazaTheme.statusReserved,
                  actions: ['Marcar disponible', 'Cerrar operación', 'Editar'],
                ),
                _buildPropertyCard(
                  title: 'Terrenos en Urubó',
                  price: 'Consultar',
                  status: 'PAUSADO',
                  statusColor: KazaTheme.statusPaused,
                  actions: ['Reactivar', 'Editar', 'Retirar'],
                ),
                _buildPropertyCard(
                  title: 'Borrador: casa zona norte',
                  price: 'DRAFT',
                  status: 'DRAFT',
                  statusColor: KazaTheme.textMuted,
                  actions: ['Continuar borrador', 'Eliminar borrador'],
                  isDraft: true,
                ),
              ],
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

  Widget _buildPropertyCard({
    required String title,
    required String price,
    required String status,
    required Color statusColor,
    required List<String> actions,
    bool isDraft = false,
  }) {
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
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(price, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDraft ? KazaTheme.textMuted : KazaTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
                  onPressed: () {},
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
}
