import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/kaza_pin_painter.dart';
import '../providers/map_properties_provider.dart';
import '../widgets/floating_filters.dart';
import '../widgets/layers_selector_sheet.dart';
import '../widgets/map_empty_states.dart';
import '../widgets/map_list_toggle.dart';
import '../widgets/poi_layer_widget.dart';
import 'property_state_wrapper.dart';
import 'cluster_bottom_sheet.dart';

/// 🗺️ MAPA (Home) — KAZA Map-First Experience
/// Matches KAZA Master Design v1.0 with all 17 components
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(-17.7833, -63.1821); // Santa Cruz, Bolivia
  double _currentZoom = 13.5;

  PropertyMapItem? _selectedProperty;
  String _selectedOperation = 'Comprar';
  int _minRooms = 0;
  RangeValues _priceRange = const RangeValues(0, 1000000);

  // Polygon Drawing Mode State
  bool _isDrawingPolygon = false;
  final List<LatLng> _polygonPoints = [];

  // List toggle
  bool _showListOverlay = false;

  // Layer visibility
  bool _showProperties = true;
  bool _showPoi = false;
  bool _showTransport = false;
  bool _showEducation = false;
  bool _showHealth = false;
  bool _showCommerce = false;
  bool _showNeighborhoods = false;

  // POI data
  late List<PoiItem> _mockPois;

  @override
  void initState() {
    super.initState();
    _mockPois = PoiLayerBuilder.generateMockPois(_initialCenter);
  }

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
          content: Text('🗺️ Filtro aplicado: Polígono de ${_polygonPoints.length} vértices'),
          backgroundColor: KazaTheme.azulKaza,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    setState(() {
      _isDrawingPolygon = false;
    });
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

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PriceFilterSheet(
        initialRange: _priceRange,
        onApply: (range) {
          setState(() => _priceRange = range);
        },
      ),
    );
  }

  void _showRoomsFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoomsFilterSheet(
        initialRooms: _minRooms,
        onApply: (rooms) {
          setState(() => _minRooms = rooms);
        },
      ),
    );
  }

  void _showLayersSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LayersSelectorSheet(
        showProperties: _showProperties,
        showPoi: _showPoi,
        showTransport: _showTransport,
        showEducation: _showEducation,
        showHealth: _showHealth,
        showCommerce: _showCommerce,
        showNeighborhoods: _showNeighborhoods,
        onApply: ({
          bool showProperties = true,
          bool showPoi = false,
          bool showTransport = false,
          bool showEducation = false,
          bool showHealth = false,
          bool showCommerce = false,
          bool showNeighborhoods = false,
        }) {
          setState(() {
            _showProperties = showProperties;
            _showPoi = showPoi;
            _showTransport = showTransport;
            _showEducation = showEducation;
            _showHealth = showHealth;
            _showCommerce = showCommerce;
            _showNeighborhoods = showNeighborhoods;
          });
        },
      ),
    );
  }

  List<PropertyMapItem> _filterProperties(List<PropertyMapItem> properties) {
    return properties.where((prop) {
      // 1. Filter by operation
      final opLower = prop.operation.toLowerCase();
      if (_selectedOperation == 'Comprar' && !opLower.contains('venta') && !opLower.contains('vender')) return false;
      if (_selectedOperation == 'Alquilar' && !opLower.contains('alquiler') && !opLower.contains('alquilar') && !opLower.contains('temporal')) return false;
      if (_selectedOperation == 'Anticrético' && !opLower.contains('anticretico') && !opLower.contains('anticrético') && !opLower.contains('anticret')) return false;

      // 2. Filter by min rooms
      if (_minRooms > 0 && prop.bedrooms < _minRooms) return false;

      return true;
    }).toList();
  }

  List<PropertyMapItem> _clusterProperties(List<PropertyMapItem> items, double zoom) {
    if (items.isEmpty) return [];
    
    // At high zoom, use tiny grid to only group identical coordinates
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
          // ━━━ 1. BASE MAP VIEWPORT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          propertiesAsync.when(
            loading: () => Stack(
              children: [
                _buildBaseMap([], []),
                const MapSearchingState(),
              ],
            ),
            error: (err, stack) => Stack(
              children: [
                _buildBaseMap([], []),
                MapNoConnectionState(
                  onRetry: () => ref.invalidate(mapPropertiesProvider),
                ),
              ],
            ),
            data: (properties) {
              final filteredProperties = _filterProperties(properties);
              final clusteredProperties = _clusterProperties(filteredProperties, _currentZoom);

              if (filteredProperties.isEmpty && properties.isNotEmpty) {
                return Stack(
                  children: [
                    _buildBaseMap([], []),
                    MapNoResultsState(
                      onModifySearch: () {
                        setState(() {
                          _selectedOperation = 'Comprar';
                          _minRooms = 0;
                          _priceRange = const RangeValues(0, 1000000);
                        });
                      },
                    ),
                  ],
                );
              }

              // Build POI markers
              final poiMarkers = (_showPoi || _showEducation || _showHealth || _showCommerce || _showTransport)
                  ? PoiLayerBuilder.buildMarkers(
                      pois: _mockPois,
                      showEducation: _showEducation || _showPoi,
                      showHealth: _showHealth || _showPoi,
                      showCommerce: _showCommerce || _showPoi,
                      showTransport: _showTransport || _showPoi,
                    )
                  : <Marker>[];

              return _buildBaseMap(clusteredProperties, poiMarkers);
            },
          ),

          // ━━━ 2. TOP SEARCH BAR + FLOATING FILTERS ━━━━━━━━━━━━━━━━━━━━━━━
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: KazaResponsive.horizontalPadding(context),
                vertical: 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  Container(
                    height: 50,
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
                        const Icon(Icons.search_rounded, color: KazaTheme.grisMedio, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: TextField(
                            style: TextStyle(fontSize: 14, color: KazaTheme.azulKaza),
                            decoration: InputDecoration(
                              hintText: 'Buscar barrio, dirección o zona',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Floating filter pills
                  FloatingFilters(
                    selectedOperation: _selectedOperation,
                    onOperationChanged: (op) {
                      setState(() => _selectedOperation = op);
                    },
                    onPriceTap: _showPriceFilter,
                    onRoomsTap: _showRoomsFilter,
                  ),
                ],
              ),
            ),
          ),

          // ━━━ 3. POLYGON DRAWING CONTROLS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (_isDrawingPolygon)
            Positioned(
              bottom: 100,
              left: KazaResponsive.horizontalPadding(context),
              right: KazaResponsive.horizontalPadding(context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Dibuja el área que\nquieres explorar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: KazaTheme.azulKaza,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KazaTheme.azulKaza,
                              side: const BorderSide(color: KazaTheme.n100),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _clearPolygon,
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KazaTheme.azulKaza,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _polygonPoints.length >= 3 ? _applyPolygonFilter : null,
                            child: const Text('Buscar aquí', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ━━━ 4. RIGHT-SIDE ACTION BUTTONS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          Positioned(
            right: KazaResponsive.horizontalPadding(context),
            bottom: _selectedProperty != null ? 260 : (_showListOverlay ? 320 : 24),
            child: Column(
              children: [
                // Zoom In button
                _MapActionButton(
                  heroTag: 'zoom_in_btn',
                  icon: Icons.add_rounded,
                  onTap: () {
                    final center = _mapController.camera.center;
                    final zoom = (_currentZoom + 1.0).clamp(1.0, 18.0);
                    _mapController.move(center, zoom);
                  },
                ),
                const SizedBox(height: 8),
                // Zoom Out button
                _MapActionButton(
                  heroTag: 'zoom_out_btn',
                  icon: Icons.remove_rounded,
                  onTap: () {
                    final center = _mapController.camera.center;
                    final zoom = (_currentZoom - 1.0).clamp(1.0, 18.0);
                    _mapController.move(center, zoom);
                  },
                ),
                const SizedBox(height: 8),
                // Layers button
                _MapActionButton(
                  heroTag: 'layers_btn',
                  icon: Icons.layers_rounded,
                  onTap: _showLayersSelector,
                ),
                const SizedBox(height: 8),
                // Draw polygon button
                _MapActionButton(
                  heroTag: 'draw_poly_btn',
                  icon: Icons.draw_rounded,
                  isActive: _isDrawingPolygon,
                  onTap: () {
                    setState(() {
                      _isDrawingPolygon = !_isDrawingPolygon;
                      if (!_isDrawingPolygon) _polygonPoints.clear();
                    });
                  },
                ),
                const SizedBox(height: 8),
                // My location button
                _MapActionButton(
                  heroTag: 'near_me',
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    _mapController.move(_initialCenter, 14);
                  },
                ),
              ],
            ),
          ),

          // ━━━ 5. LIST TOGGLE BUTTON (Left side) ━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (!_isDrawingPolygon && _selectedProperty == null)
            Positioned(
              left: KazaResponsive.horizontalPadding(context),
              bottom: _showListOverlay ? 320 : 24,
              child: _MapActionButton(
                heroTag: 'list_toggle',
                icon: _showListOverlay ? Icons.map_rounded : Icons.list_rounded,
                onTap: () {
                  setState(() => _showListOverlay = !_showListOverlay);
                },
              ),
            ),

          // ━━━ 6. LIST OVERLAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (_showListOverlay)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height * 0.4,
              child: propertiesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (properties) {
                  final filtered = _filterProperties(properties);
                  return MapListOverlay(
                    properties: filtered,
                    onClose: () => setState(() => _showListOverlay = false),
                    onPropertyTap: (prop) {
                      setState(() {
                        _selectedProperty = prop;
                        _showListOverlay = false;
                      });
                      _mapController.move(prop.location, 16);
                    },
                    onFavoriteTap: (prop) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${prop.title} guardado'),
                          backgroundColor: KazaTheme.azulKaza,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          // ━━━ 7. PROPERTY PREVIEW CARD ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (_selectedProperty != null)
            Positioned(
              left: KazaResponsive.horizontalPadding(context),
              right: KazaResponsive.horizontalPadding(context),
              bottom: KazaResponsive.bottomSafeArea(context) + 12,
              child: _PropertyPreviewCard(
                property: _selectedProperty!,
                onClose: () => setState(() => _selectedProperty = null),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyStateWrapper(
                        propertyId: _selectedProperty!.id,
                        preloadedProperty: _selectedProperty,
                      ),
                    ),
                  );
                },
                onConsultPrice: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyStateWrapper(
                        propertyId: _selectedProperty!.id,
                        preloadedProperty: _selectedProperty,
                      ),
                    ),
                  );
                },
                onFavorite: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_selectedProperty!.title} guardado'),
                      backgroundColor: KazaTheme.azulKaza,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the base map with tile layer, polygon, and markers
  Widget _buildBaseMap(List<PropertyMapItem> clusteredProperties, List<Marker> poiMarkers) {
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
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?api_key=eyJhbGciOiJIUzI1NiJ9.eyJhIjoiYWNfNjk2c28xMXciLCJqdGkiOiJjZDUyNjZmNCJ9.bImw1wi0pDZDr5NVWvRobihoVWJr2rvzN9xrNeo92Lo',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.kaza.app',
        ),

        // Polygon Layer
        if (_polygonPoints.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _polygonPoints,
                color: KazaTheme.azulKaza.withValues(alpha: 0.12),
                borderColor: KazaTheme.azulKaza.withValues(alpha: 0.6),
                borderStrokeWidth: 2.5,
              ),
            ],
          ),

        // Property Marker Layer
        if (_showProperties)
          MarkerLayer(
            markers: clusteredProperties.map((prop) {
              final isSelected = _selectedProperty?.id == prop.id;
              final typeIcon = _getIconForType(prop.type);
              final hasCluster = prop.propertyCount > 1;

              return Marker(
                point: prop.location,
                width: hasCluster ? 52 : 40,
                height: hasCluster ? 52 : 48,
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
                    child: SizedBox(
                      key: ValueKey('${prop.id}_$isSelected'),
                      width: hasCluster ? 52 : 40,
                      height: hasCluster ? 52 : 48,
                      child: CustomPaint(
                        painter: KazaPinPainter(
                          icon: typeIcon,
                          isSelected: isSelected,
                          propertyCount: prop.propertyCount,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        // POI Marker Layer
        if (poiMarkers.isNotEmpty)
          MarkerLayer(markers: poiMarkers),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROPERTY PREVIEW CARD — "12 CONSULTAR PRECIO" + "16 PREVIEW EN MAPA"
// ═══════════════════════════════════════════════════════════════════════════════

class _PropertyPreviewCard extends StatelessWidget {
  final PropertyMapItem property;
  final VoidCallback onClose;
  final VoidCallback onTap;
  final VoidCallback onConsultPrice;
  final VoidCallback onFavorite;

  const _PropertyPreviewCard({
    required this.property,
    required this.onClose,
    required this.onTap,
    required this.onConsultPrice,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image + Close + Favorite buttons
            Stack(
              children: [
                // Image
                property.imageUrl != null
                    ? Image.network(
                        property.imageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
                // Close button
                Positioned(
                  top: 8,
                  left: 8,
                  child: _CircleButton(
                    icon: Icons.close,
                    onTap: onClose,
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: _CircleButton(
                    icon: Icons.favorite_border_rounded,
                    onTap: onFavorite,
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: KazaTheme.azulKaza,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Address
                  Text(
                    property.address ?? 'Sin dirección específica',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KazaTheme.grisMedio,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Metrics row
                  Row(
                    children: [
                      _MetricChip(icon: Icons.straighten_rounded, label: property.surface),
                      const SizedBox(width: 12),
                      _MetricChip(icon: Icons.king_bed_outlined, label: '${property.bedrooms} amb.'),
                      const SizedBox(width: 12),
                      _MetricChip(icon: Icons.bathtub_outlined, label: '${property.bathrooms} baño${property.bathrooms != 1 ? 's' : ''}'),
                      if (property.floorsTotal > 1) ...[
                        const SizedBox(width: 12),
                        _MetricChip(icon: Icons.apartment_rounded, label: '${property.floorsTotal}° piso'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Consult price button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KazaTheme.azulKaza,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: onConsultPrice,
                      child: const Text(
                        'Consultar precio',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Save prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 14, color: KazaTheme.grisMedio),
                      const SizedBox(width: 6),
                      const Text(
                        'Guarda esta propiedad para seguirla y recibir novedades',
                        style: TextStyle(
                          color: KazaTheme.grisMedio,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 140,
      color: const Color(0xFFF0F4F8),
      width: double.infinity,
      child: const Icon(Icons.home_work_rounded, color: Colors.black12, size: 48),
    );
  }
}

/// Small circular button overlay on image
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: KazaTheme.azulKaza),
      ),
    );
  }
}

/// Metric chip (surface, rooms, bathrooms, floor)
class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: KazaTheme.grisMedio),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: KazaTheme.azulKaza,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Floating action button for map controls
class _MapActionButton extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _MapActionButton({
    required this.heroTag,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? KazaTheme.azulKaza : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : KazaTheme.azulKaza,
          size: 22,
        ),
      ),
    );
  }
}
