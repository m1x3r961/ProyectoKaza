import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

/// 🏷️ FLOATING FILTER PILLS — Comprar, Precio, Ambientes
/// Appears below the search bar on the map. Matches KAZA Master Design "02 FILTROS FLOTANTES"
class FloatingFilters extends StatelessWidget {
  final String selectedOperation;
  final ValueChanged<String> onOperationChanged;
  final VoidCallback onPriceTap;
  final VoidCallback onRoomsTap;

  const FloatingFilters({
    super.key,
    required this.selectedOperation,
    required this.onOperationChanged,
    required this.onPriceTap,
    required this.onRoomsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Comprar / Alquilar / Anticrético dropdown pill
          _OperationDropdownPill(
            selectedOperation: selectedOperation,
            onChanged: onOperationChanged,
          ),
          const SizedBox(width: 8),
          // Precio pill
          _FilterPill(
            label: 'Precio',
            onTap: onPriceTap,
          ),
          const SizedBox(width: 8),
          // Ambientes pill
          _FilterPill(
            label: 'Ambientes',
            onTap: onRoomsTap,
          ),
        ],
      ),
    );
  }
}

/// Operation dropdown pill (Comprar ▼)
class _OperationDropdownPill extends StatelessWidget {
  final String selectedOperation;
  final ValueChanged<String> onChanged;

  const _OperationDropdownPill({
    required this.selectedOperation,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      itemBuilder: (ctx) => [
        _buildMenuItem('Comprar', selectedOperation == 'Comprar'),
        _buildMenuItem('Alquilar', selectedOperation == 'Alquilar'),
        _buildMenuItem('Anticrético', selectedOperation == 'Anticrético'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: KazaTheme.azulKaza,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedOperation,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (isSelected)
            const Icon(Icons.check_rounded, size: 18, color: KazaTheme.azulKaza)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: KazaTheme.azulKaza,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic filter pill (Precio ▼, Ambientes ▼)
class _FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _FilterPill({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? KazaTheme.azulKaza : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : KazaTheme.azulKaza,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : KazaTheme.azulKaza,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// 💰 PRICE FILTER BOTTOM SHEET
class PriceFilterSheet extends StatefulWidget {
  final RangeValues initialRange;
  final ValueChanged<RangeValues> onApply;

  const PriceFilterSheet({
    super.key,
    this.initialRange = const RangeValues(20000, 350000),
    required this.onApply,
  });

  @override
  State<PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<PriceFilterSheet> {
  late RangeValues _range;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
  }

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
          const Text(
            'Rango de Precio',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: KazaTheme.azulKaza,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatPrice(_range.start)} — ${_formatPrice(_range.end)}',
            style: const TextStyle(
              color: KazaTheme.coralKaza,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: _range,
            min: 0,
            max: 1000000,
            divisions: 100,
            activeColor: KazaTheme.azulKaza,
            inactiveColor: KazaTheme.n100,
            onChanged: (values) {
              setState(() => _range = values);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onApply(_range);
                Navigator.pop(context);
              },
              child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🛏️ ROOMS FILTER BOTTOM SHEET
class RoomsFilterSheet extends StatefulWidget {
  final int initialRooms;
  final ValueChanged<int> onApply;

  const RoomsFilterSheet({
    super.key,
    this.initialRooms = 0,
    required this.onApply,
  });

  @override
  State<RoomsFilterSheet> createState() => _RoomsFilterSheetState();
}

class _RoomsFilterSheetState extends State<RoomsFilterSheet> {
  late int _selectedRooms;

  @override
  void initState() {
    super.initState();
    _selectedRooms = widget.initialRooms;
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
          const Text(
            'Ambientes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: KazaTheme.azulKaza,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [0, 1, 2, 3, 4, 5].map((rooms) {
              final isSelected = _selectedRooms == rooms;
              final label = rooms == 0 ? 'Todos' : '$rooms+';
              return GestureDetector(
                onTap: () => setState(() => _selectedRooms = rooms),
                child: Container(
                  width: 64,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? KazaTheme.azulKaza : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? KazaTheme.azulKaza : KazaTheme.n100,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : KazaTheme.azulKaza,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onApply(_selectedRooms);
                Navigator.pop(context);
              },
              child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
