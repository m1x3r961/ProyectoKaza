import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

/// ⚙️ MAP FILTER BOTTOM SHEET — Full Filters Panel
/// Accessible via search bar or filter icon
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
  int _minRooms = 1;

  String _formatPrice(double val) {
    if (val >= 1000000) return '\$${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '\$${(val / 1000).toStringAsFixed(0)}K';
    return '\$${val.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Filtros',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: KazaTheme.azulKaza),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _operation = 'VENTA';
                    _propertyType = 'Todos';
                    _priceRange = const RangeValues(20000, 350000);
                    _minRooms = 1;
                  });
                },
                child: const Text(
                  'Limpiar',
                  style: TextStyle(
                    color: KazaTheme.coralKaza,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close, color: KazaTheme.grisMedio),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Draw area action
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onStartDrawPolygon();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KazaTheme.azulKaza.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.draw_rounded, color: KazaTheme.azulKaza, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dibujar área en el mapa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.azulKaza)),
                        SizedBox(height: 2),
                        Text('Delimita una zona con el dedo', style: TextStyle(fontSize: 12, color: KazaTheme.grisMedio)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: KazaTheme.azulKaza),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Operation
          const Text('Operación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.azulKaza)),
          const SizedBox(height: 10),
          Row(
            children: ['VENTA', 'ALQUILER', 'ANTICRETICO'].map((op) {
              final isSelected = _operation == op;
              final label = op == 'ANTICRETICO' ? 'Anticrético' : op[0] + op.substring(1).toLowerCase();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _operation = op),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? KazaTheme.azulKaza : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? KazaTheme.azulKaza : KazaTheme.n100,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : KazaTheme.azulKaza,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Property type
          const Text('Tipo de propiedad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.azulKaza)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Todos', 'Departamento', 'Casa', 'Terreno', 'Oficina', 'Local'].map((t) {
              final isSelected = _propertyType == t;
              return GestureDetector(
                onTap: () => setState(() => _propertyType = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? KazaTheme.azulKaza : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? KazaTheme.azulKaza : KazaTheme.n100,
                    ),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: isSelected ? Colors.white : KazaTheme.azulKaza,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Min rooms
          const Text('Ambientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.azulKaza)),
          const SizedBox(height: 10),
          Row(
            children: [1, 2, 3, 4].map((rooms) {
              final isSelected = _minRooms == rooms;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _minRooms = rooms),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? KazaTheme.azulKaza : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? KazaTheme.azulKaza : KazaTheme.n100,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rooms+',
                        style: TextStyle(
                          color: isSelected ? Colors.white : KazaTheme.azulKaza,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Price range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Precio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.azulKaza)),
              Text(
                '${_formatPrice(_priceRange.start)} — ${_formatPrice(_priceRange.end)}',
                style: const TextStyle(color: KazaTheme.coralKaza, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000000,
            divisions: 100,
            activeColor: KazaTheme.azulKaza,
            inactiveColor: KazaTheme.n100,
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
          ),

          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onApply();
              },
              child: const Text('Aplicar filtros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
