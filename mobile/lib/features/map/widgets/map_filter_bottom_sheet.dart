import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

/// ⚙️ MAP FILTER BOTTOM SHEET - Panel de Filtros Geoespaciales y de Dominio
class MapFilterBottomSheet extends StatefulWidget {
  final VoidCallback onApply;
  final VoidCallback onStartDrawPolygon;

  const MapFilterBottomSheet({
    super.key,
    required this.onApply,
    required this.onStartDrawPolygon,
  });

  @override
  State<MapFilterBottomSheet> createState() => _MapFilterBottomSheetState();
}

class _MapFilterBottomSheetState extends State<MapFilterBottomSheet> {
  String _operation = 'VENTA';
  String _propertyType = 'Todos';
  RangeValues _priceRange = const RangeValues(20000, 350000);
  int _selectedRadiusMeters = 1000;
  int _minRooms = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: KazaTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: KazaTheme.glassBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.tune, color: KazaTheme.primaryTealLight),
              const SizedBox(width: 8),
              const Text(
                'Filtros de Búsqueda Geoespacial',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: KazaTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action: Draw Polygon on Map
          Card(
            color: KazaTheme.primaryTeal.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: KazaTheme.primaryTealLight),
            ),
            child: ListTile(
              leading: const Icon(Icons.draw, color: KazaTheme.primaryTealLight),
              title: const Text('Dibujar Polígono en el Mapa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Delimita un área personalizada con el dedo', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: KazaTheme.primaryTealLight),
              onTap: () {
                Navigator.pop(context);
                widget.onStartDrawPolygon();
              },
            ),
          ),

          const SizedBox(height: 16),

          // Operación
          const Text('Tipo de Operación Comercial:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'VENTA', label: Text('Venta')),
              ButtonSegment(value: 'ALQUILER', label: Text('Alquiler')),
              ButtonSegment(value: 'ANTICRETICO', label: Text('Anticrético')),
            ],
            selected: {_operation},
            onSelectionChanged: (val) {
              setState(() => _operation = val.first);
            },
          ),

          const SizedBox(height: 16),

          // Tipo de Inmueble
          const Text('Tipo de Propiedad:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _propertyType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: ['Todos', 'Departamento', 'Casa', 'Terreno', 'Oficina', 'Local Comercial'].map((t) {
              return DropdownMenuItem(value: t, child: Text(t));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _propertyType = val);
            },
          ),

          const SizedBox(height: 16),

          // Radio de Distancia Cerca de Mí (PostGIS ST_DWithin)
          const Text('Radio Cerca de Mí (PostGIS Metros):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [500, 1000, 2000, 5000].map((meters) {
              final label = meters >= 1000 ? '${(meters / 1000).toInt()} km' : '$meters m';
              final isSel = _selectedRadiusMeters == meters;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 11)),
                    selected: isSel,
                    selectedColor: KazaTheme.primaryTeal,
                    backgroundColor: KazaTheme.cardSurface,
                    onSelected: (_) {
                      setState(() => _selectedRadiusMeters = meters);
                    },
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Mínimo de Dormitorios
          const Text('Mínimo de Dormitorios:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3, 4].map((rooms) {
              final isSel = _minRooms == rooms;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('$rooms+ dorms', style: const TextStyle(fontSize: 11)),
                  selected: isSel,
                  selectedColor: KazaTheme.primaryTeal,
                  backgroundColor: KazaTheme.cardSurface,
                  onSelected: (_) {
                    setState(() => _minRooms = rooms);
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Rango de Precio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rango de Precio (USD):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                '\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}',
                style: const TextStyle(color: KazaTheme.primaryTealLight, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000000,
            divisions: 100,
            activeColor: KazaTheme.primaryTealLight,
            inactiveColor: Colors.white12,
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
          ),

          const SizedBox(height: 20),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onApply();
              },
              child: const Text('Aplicar Filtros al Mapa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
