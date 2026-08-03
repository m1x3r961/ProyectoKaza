import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../../../core/widgets/kaza_logo_widget.dart';
import '../../../core/widgets/kaza_pin_painter.dart';
import '../providers/map_properties_provider.dart';
import '../widgets/map_filter_bottom_sheet.dart';
import 'property_detail_screen.dart';
import 'cluster_bottom_sheet.dart';

/// 🗺️ MAPA (Home) - Kaza Map-First Experience & Polygon Drawing Engine
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(-17.7833, -63.1821); // Santa Cruz, Bolivia
  double _currentZoom = 13.5;

  PropertyMapItem? _selectedProperty;
  String _selectedOperation = 'Comprar';
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

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('casa')) return Icons.home_work_rounded;
    if (t.contains('departamento') || t.contains('condominio')) return Icons.apartment_rounded;
    if (t.contains('terreno') || t.contains('lote') || t.contains('rural')) return Icons.landscape_rounded;
    if (t.contains('oficina') || t.contains('comercial') || t.contains('local')) return Icons.storefront_rounded;
    if (t.contains('industrial')) return Icons.factory_rounded;
    return Icons.location_on_rounded;
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

  Widget _buildOperationPill(String title, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KazaTheme.azulKaza : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : KazaTheme.azulKaza,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
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

  void _showClusterBottomSheet(PropertyMapItem clusterItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
        child: ClusterBottomSheet(clusterItem: clusterItem),
      ),
    );
  }

  List<PropertyMapItem> _clusterProperties(List<PropertyMapItem> items, double zoom) {
    if (items.isEmpty) return [];
    
    // Si zoom > 16, usar un grid diminuto para agrupar solo los que tienen coordenadas IDÉNTICAS
    double gridSize = zoom > 16.0 ? 0.00001 : (0.005 * math.pow(2, 14 - zoom));
    
    Map<String, List<PropertyMapItem>> grid = {};
    for (var item in items) {
      int gridX = (item.location.latitude / gridSize).round();
      int gridY = (item.location.longitude / gridSize).round();
      String key = '$gridX,$gridY';
      grid.putIfAbsent(key, () => []).add(item);
    }
    
    List<PropertyMapItem> clusters = [];
    for (var cell in grid.values) {
      if (cell.length == 1) {
        clusters.add(cell.first);
      } else {
        double sumLat = 0;
        double sumLng = 0;
        for (var item in cell) {
          sumLat += item.location.latitude;
          sumLng += item.location.longitude;
        }
        clusters.add(PropertyMapItem(
          id: 'cluster_${cell.first.id}',
          title: 'Múltiples propiedades',
          price: '',
          operation: cell.first.operation,
          type: cell.first.type,
          location: LatLng(sumLat / cell.length, sumLng / cell.length),
          bedrooms: 0,
          bathrooms: 0,
          surface: '',
          isPlus: false,
          trustLabel: '',
          isOrg: false,
          propertyCount: cell.length,
          subItems: cell,
        ));
      }
    }
    return clusters;
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
              final filteredProperties = properties.where((prop) {
                // 1. Filtrar por Operación (Comprar/Alquilar/Anticrético)
                final opLower = prop.operation.toLowerCase();
                if (_selectedOperation == 'Comprar' && !opLower.contains('venta') && !opLower.contains('vender')) return false;
                if (_selectedOperation == 'Alquilar' && !opLower.contains('alquiler') && !opLower.contains('alquilar')) return false;
                if (_selectedOperation == 'Anticrético' && !opLower.contains('anticretico') && !opLower.contains('anticrético') && !opLower.contains('anticret')) return false;

                // 2. Filtrar por Categoría
                if (_selectedCategory != 'Todos' && _selectedCategory != 'Más') {
                  final tLower = prop.type.toLowerCase();
                  if (_selectedCategory == 'Casa' && !tLower.contains('casa')) return false;
                  if (_selectedCategory == 'Dpto.' && !tLower.contains('departamento') && !tLower.contains('condominio')) return false;
                  if (_selectedCategory == 'Terreno' && !tLower.contains('terreno') && !tLower.contains('lote')) return false;
                  if (_selectedCategory == 'Local' && !tLower.contains('comercial') && !tLower.contains('local')) return false;
                  if (_selectedCategory == 'Oficina' && !tLower.contains('oficina')) return false;
                }
                
                return true;
              }).toList();

              final clusteredProperties = _clusterProperties(filteredProperties, _currentZoom);

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 13.5,
                  onTap: _onMapTap,
                  onPositionChanged: (camera, hasGesture) {
                    if ((_currentZoom - camera.zoom).abs() > 0.5) {
                      setState(() {
                        _currentZoom = camera.zoom;
                      });
                    }
                  },
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

                  // Marker Layer con Pines Distintivos por Tipo (Casa, Departamento, Terreno, Oficina)
                  // Badge numérico muestra cuántas propiedades hay en cada pin (WM-01 v0.2)
                  MarkerLayer(
                    markers: clusteredProperties.map((prop) {
                      final isSelected = _selectedProperty?.id == prop.id;
                      final typeIcon = _getIconForType(prop.type);
                      final hasCluster = prop.propertyCount > 1;

                      return Marker(
                        point: prop.location,
                        width: isSelected ? 135 : (hasCluster ? 56 : 44),
                        height: isSelected ? 48 : (hasCluster ? 56 : 48),
                        child: GestureDetector(
                          onTap: () {
                            if (hasCluster) {
                              _showClusterBottomSheet(prop);
                            } else {
                              setState(() => _selectedProperty = prop);
                            }
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: isSelected
                                ? Container(
                                    key: ValueKey('sel_${prop.id}'),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: KazaTheme.accentGold,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black54,
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black12,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            typeIcon,
                                            size: 14,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          prop.price,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(
                                    key: ValueKey('unsel_${prop.id}'),
                                    width: hasCluster ? 56 : 38,
                                    height: hasCluster ? 56 : 48,
                                    child: CustomPaint(
                                      painter: KazaPinPainter(
                                        icon: typeIcon,
                                        isSelected: false,
                                        propertyCount: prop.propertyCount,
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

          // 2. Top Floating Bar — Responsive search + filters
          SafeArea(
            child: Builder(
              builder: (ctx) {
                final hPad = KazaResponsive.horizontalPadding(ctx);
                final isTablet = KazaResponsive.isTablet(ctx);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              // ── KAZA Logo flotante sobre el mapa ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo animado (GIF)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const KazaAnimatedLogo(width: 54, height: 48, fit: BoxFit.cover),
                    ),
                  ),
                  // Tagline pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: KazaTheme.azulKaza.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Más que un lugar.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Row 1: Search Bar
                      Container(
                        height: isTablet ? 54 : 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(Icons.search_rounded, color: KazaTheme.azulKaza, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                style: TextStyle(fontSize: isTablet ? 15 : 14),
                                decoration: const InputDecoration(
                                  hintText: '¿Dónde quieres buscar?',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.tune_rounded, color: KazaTheme.azulKaza, size: 22),
                              onPressed: _openFilterBottomSheet,
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Row 2: Operation Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildOperationPill(
                            'Comprar',
                            isSelected: _selectedOperation == 'Comprar',
                            onTap: () => setState(() => _selectedOperation = 'Comprar'),
                          ),
                          const SizedBox(width: 8),
                          _buildOperationPill(
                            'Alquilar',
                            isSelected: _selectedOperation == 'Alquilar',
                            onTap: () => setState(() => _selectedOperation = 'Alquilar'),
                          ),
                          const SizedBox(width: 8),
                          _buildOperationPill(
                            'Anticrético',
                            isSelected: _selectedOperation == 'Anticrético',
                            onTap: () => setState(() => _selectedOperation = 'Anticrético'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Row 3: Category Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Todos', 'Casa', 'Dpto.', 'Terreno', 'Local', 'Oficina', 'Más'].map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSel,
                                selectedColor: KazaTheme.azulKaza,
                                backgroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: Colors.black12,
                                side: BorderSide.none,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : KazaTheme.azulKaza,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. Floating Polygon Drawing Controls (When in drawing mode)
          if (_isDrawingPolygon)
            Positioned(
              top: MediaQuery.of(context).padding.top + 140,
              left: KazaResponsive.horizontalPadding(context),
              right: KazaResponsive.horizontalPadding(context),
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
            right: KazaResponsive.horizontalPadding(context),
            bottom: _selectedProperty != null
                ? KazaResponsive.mapPropertyCardHeight(context) + 100
                : 20,
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

          // 5. Bottom Property Preview Card — adapts width on tablets
          if (_selectedProperty != null)
            Positioned(
              left: KazaResponsive.isTablet(context)
                  ? MediaQuery.of(context).size.width * 0.22
                  : KazaResponsive.horizontalPadding(context),
              right: KazaResponsive.isTablet(context)
                  ? MediaQuery.of(context).size.width * 0.22
                  : KazaResponsive.horizontalPadding(context),
              bottom: KazaResponsive.bottomSafeArea(context) + 12,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(property: _selectedProperty!),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: EdgeInsets.all(KazaResponsive.isTablet(context) ? 14.0 : 12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: KazaResponsive.isTablet(context) ? 100 : 84,
                            height: KazaResponsive.isTablet(context) ? 100 : 84,
                            color: Colors.grey.shade800,
                            child: Icon(_getIconForType(_selectedProperty!.type), color: Colors.white54, size: 36),
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
                                  color: KazaTheme.primaryCoralLight,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: KazaTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
