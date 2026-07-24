import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../providers/map_properties_provider.dart';
import '../widgets/map_filter_bottom_sheet.dart';

/// 🗺️ MAPA (Home) - Kaza Map-First Experience & Polygon Drawing Engine
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(-17.7833, -63.1821); // Santa Cruz, Bolivia

  PropertyMapItem? _selectedProperty;
  String _selectedCategory = 'Todos';

  // Polygon Drawing Mode State
  bool _isDrawingPolygon = false;
  final List<LatLng> _polygonPoints = [];

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isDrawingPolygon) {
      setState(() {
        _polygonPoints.add(point);
      });
    } else {
      setState(() {
        _selectedProperty = null;
      });
    }
  }

  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
      _isDrawingPolygon = false;
    });
  }

  void _applyPolygonFilter() {
    if (_polygonPoints.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗺️ Filtro aplicado: Polígono de ${_polygonPoints.length} vértices (PostGIS ST_Contains)'),
          backgroundColor: KazaTheme.primaryTeal,
        ),
      );
    }
    setState(() {
      _isDrawingPolygon = false;
    });
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapFilterBottomSheet(
        onApply: () {
          ref.invalidate(mapPropertiesProvider);
        },
        onStartDrawPolygon: () {
          setState(() {
            _isDrawingPolygon = true;
            _polygonPoints.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✍️ MODO DIBUJO: Toca el mapa para colocar vértices del polígono'),
              backgroundColor: KazaTheme.accentGold,
              duration: Duration(seconds: 4),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(mapPropertiesProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Base Map Viewport
          propertiesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: KazaTheme.primaryTealLight),
            ),
            error: (err, stack) => Center(
              child: Text('Error al cargar datos del mapa: $err'),
            ),
            data: (properties) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 13.5,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.kaza.app',
                  ),

                  // Polygon Layer
                  if (_polygonPoints.isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _polygonPoints,
                          color: KazaTheme.primaryTeal.withValues(alpha: 0.25),
                          borderColor: KazaTheme.primaryTealLight,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),

                  // Marker Layer
                  MarkerLayer(
                    markers: properties.map((prop) {
                      final isSelected = _selectedProperty?.id == prop.id;
                      return Marker(
                        point: prop.location,
                        width: 100,
                        height: 45,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedProperty = prop);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? KazaTheme.accentGold
                                  : (prop.isPlus ? KazaTheme.primaryTeal : KazaTheme.cardSurface),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.white : KazaTheme.glassBorder,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                prop.price,
                                style: TextStyle(
                                  color: isSelected || prop.isPlus ? Colors.black : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          // 2. Top Floating Bar (Search + POI Categories)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: KazaTheme.cardSurface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: KazaTheme.glassBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search, color: KazaTheme.primaryTealLight),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar ciudad, zona, barrio o edificio...',
                              hintStyle: TextStyle(color: KazaTheme.textMuted, fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune, color: KazaTheme.primaryTealLight),
                          onPressed: _openFilterBottomSheet,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Category Chips (Entorno POIs)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todos', 'Educación', 'Salud', 'Supermercados', 'Parques'].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: KazaTheme.primaryTeal,
                            backgroundColor: KazaTheme.cardSurface.withValues(alpha: 0.85),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : KazaTheme.textSecondary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Polygon Drawing Controls (When in drawing mode)
          if (_isDrawingPolygon)
            Positioned(
              top: 130,
              left: 16,
              right: 16,
              child: Card(
                color: KazaTheme.cardSurface.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.draw, color: KazaTheme.accentGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vértices: ${_polygonPoints.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearPolygon,
                        child: const Text('Limpiar', style: TextStyle(color: Colors.redAccent)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: KazaTheme.primaryTeal),
                        onPressed: _polygonPoints.length >= 3 ? _applyPolygonFilter : null,
                        child: const Text('Aplicar Área'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Floating Action Buttons (Near me & Viewport Refresh)
          Positioned(
            right: 16,
            bottom: _selectedProperty != null ? 220 : 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'draw_poly_btn',
                  backgroundColor: _isDrawingPolygon ? KazaTheme.accentGold : KazaTheme.cardSurface,
                  child: Icon(Icons.draw, color: _isDrawingPolygon ? Colors.black : KazaTheme.primaryTealLight),
                  onPressed: () {
                    setState(() {
                      _isDrawingPolygon = !_isDrawingPolygon;
                      if (!_isDrawingPolygon) _polygonPoints.clear();
                    });
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'near_me',
                  backgroundColor: KazaTheme.cardSurface,
                  child: const Icon(Icons.my_location, color: KazaTheme.primaryTealLight),
                  onPressed: () {
                    _mapController.move(_initialCenter, 14);
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'refresh_area',
                  backgroundColor: KazaTheme.cardSurface,
                  child: const Icon(Icons.refresh, color: KazaTheme.textPrimary),
                  onPressed: () {
                    ref.invalidate(mapPropertiesProvider);
                  },
                ),
              ],
            ),
          ),

          // 5. Bottom Property Preview Card (When marker is selected)
          if (_selectedProperty != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.home, color: Colors.white54, size: 36),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                if (_selectedProperty!.isPlus) ...[
                                  const KazaPlusBadge(),
                                  const SizedBox(width: 6),
                                ],
                                KazaTrustBadge(
                                  label: _selectedProperty!.trustLabel,
                                  isOrganization: _selectedProperty!.isOrg,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedProperty!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedProperty!.bedrooms} Dorm · ${_selectedProperty!.bathrooms} Baños · ${_selectedProperty!.surface}',
                              style: const TextStyle(
                                color: KazaTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedProperty!.price,
                              style: const TextStyle(
                                color: KazaTheme.primaryTealLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
