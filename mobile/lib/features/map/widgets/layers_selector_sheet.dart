import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

/// 🗂️ LAYERS SELECTOR SHEET — "11 SELECTOR DE CAPAS"
/// Bottom sheet to toggle map layer visibility (Properties, POIs, Transport, etc.)
class LayersSelectorSheet extends StatefulWidget {
  final bool showProperties;
  final bool showPoi;
  final bool showTransport;
  final bool showEducation;
  final bool showHealth;
  final bool showCommerce;
  final bool showNeighborhoods;
  final Function({
    bool showProperties,
    bool showPoi,
    bool showTransport,
    bool showEducation,
    bool showHealth,
    bool showCommerce,
    bool showNeighborhoods,
  }) onApply;

  const LayersSelectorSheet({
    super.key,
    this.showProperties = true,
    this.showPoi = false,
    this.showTransport = false,
    this.showEducation = false,
    this.showHealth = false,
    this.showCommerce = false,
    this.showNeighborhoods = false,
    required this.onApply,
  });

  @override
  State<LayersSelectorSheet> createState() => _LayersSelectorSheetState();
}

class _LayersSelectorSheetState extends State<LayersSelectorSheet> {
  late bool _showProperties;
  late bool _showPoi;
  late bool _showTransport;
  late bool _showEducation;
  late bool _showHealth;
  late bool _showCommerce;
  late bool _showNeighborhoods;

  @override
  void initState() {
    super.initState();
    _showProperties = widget.showProperties;
    _showPoi = widget.showPoi;
    _showTransport = widget.showTransport;
    _showEducation = widget.showEducation;
    _showHealth = widget.showHealth;
    _showCommerce = widget.showCommerce;
    _showNeighborhoods = widget.showNeighborhoods;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Capas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: KazaTheme.azulKaza,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: KazaTheme.grisMedio),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Layer toggles
          _LayerToggle(
            icon: Icons.location_on_rounded,
            iconColor: KazaTheme.azulKaza,
            label: 'Propiedades',
            value: _showProperties,
            onChanged: (v) => setState(() => _showProperties = v),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _LayerToggle(
            icon: Icons.place_rounded,
            iconColor: const Color(0xFF27AE60),
            label: 'Puntos de interés',
            value: _showPoi,
            onChanged: (v) => setState(() => _showPoi = v),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _LayerToggle(
            icon: Icons.directions_bus_rounded,
            iconColor: KazaTheme.semanticInfo,
            label: 'Transporte público',
            value: _showTransport,
            onChanged: (v) => setState(() => _showTransport = v),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _LayerToggle(
            icon: Icons.school_rounded,
            iconColor: const Color(0xFF9C27B0),
            label: 'Educación',
            value: _showEducation,
            onChanged: (v) => setState(() => _showEducation = v),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _LayerToggle(
            icon: Icons.local_hospital_rounded,
            iconColor: KazaTheme.semanticError,
            label: 'Salud',
            value: _showHealth,
            onChanged: (v) => setState(() => _showHealth = v),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _LayerToggle(
            icon: Icons.storefront_rounded,
            iconColor: KazaTheme.semanticWarning,
            label: 'Comercios',
            value: _showCommerce,
            onChanged: (v) => setState(() => _showCommerce = v),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _LayerToggle(
            icon: Icons.map_rounded,
            iconColor: const Color(0xFFF6BD7B),
            label: 'Barrios / Contexto',
            value: _showNeighborhoods,
            onChanged: (v) => setState(() => _showNeighborhoods = v),
          ),

          const SizedBox(height: 20),
          // Apply button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: KazaTheme.azulKaza,
                side: const BorderSide(color: KazaTheme.azulKaza),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onApply(
                  showProperties: _showProperties,
                  showPoi: _showPoi,
                  showTransport: _showTransport,
                  showEducation: _showEducation,
                  showHealth: _showHealth,
                  showCommerce: _showCommerce,
                  showNeighborhoods: _showNeighborhoods,
                );
                Navigator.pop(context);
              },
              child: const Text('Gestionar capas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LayerToggle({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: KazaTheme.azulKaza,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: KazaTheme.azulKaza,
            activeTrackColor: KazaTheme.azulKaza.withValues(alpha: 0.3),
            inactiveThumbColor: KazaTheme.grisMedio,
            inactiveTrackColor: KazaTheme.n100,
          ),
        ],
      ),
    );
  }
}
