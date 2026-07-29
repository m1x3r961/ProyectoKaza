import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/widgets/kaza_pin_painter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../map/providers/map_properties_provider.dart';
import '../../media/models/kaza_media_item.dart';
import '../../media/widgets/media_picker_widget.dart';

/// ➕ PUBLICAR WIZARD v2 — Diseño WM-03 v0.3 FINAL
/// Slider horizontal de 6 pasos con dots de progreso animados
class PublishScreen extends ConsumerStatefulWidget {
  const PublishScreen({super.key});
  @override
  ConsumerState<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends ConsumerState<PublishScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  // Step 1
  String _operationType = 'Vender';
  String _propertyType = 'Departamento';

  // Step 2
  double _selectedLat = -17.7833;
  double _selectedLng = -63.1821;
  final _addressCtrl = TextEditingController(text: 'Av. San Martín · Equipetrol');

  // Step 3
  final _terrainCtrl = TextEditingController(text: '300');
  final _builtCtrl = TextEditingController(text: '180');
  final _bedroomsCtrl = TextEditingController(text: '3');
  final _bathroomsCtrl = TextEditingController(text: '3');
  final _garageCtrl = TextEditingController(text: '2');
  final _floorCtrl = TextEditingController(text: '3');

  // Step 4 (Media & Price) -> now integrated in Step 3
  List<KazaMediaItem> _mediaItems = [];
  String _currency = 'BOB';
  final _priceCtrl = TextEditingController(text: '850000');
  bool _consultarPrecio = false;

  // Step 5 (Description & Plus) -> now mostly in Step 3, plus in Step 4
  final _titleCtrl = TextEditingController(text: 'Casa contemporánea con jardín y galería');
  final _descCtrl = TextEditingController();
  bool _plusVideo = false;
  bool _plusPlano = false;
  bool _plus3D = false;
  bool _plusImagen = false;
  
  // Step 5 (Review)
  bool _msgKaza = true;
  bool _msgWhatsapp = true;
  bool _call = false;
  String _precisionType = 'Zona aproximada';

  @override
  void dispose() {
    _pageController.dispose();
    _addressCtrl.dispose();
    _terrainCtrl.dispose();
    _builtCtrl.dispose();
    _bedroomsCtrl.dispose();
    _bathroomsCtrl.dispose();
    _garageCtrl.dispose();
    _floorCtrl.dispose();
    _priceCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _publish() async {
    final authState = ref.read(kazaAuthProvider);
    final userId = authState.userId;
    final agentName = authState.fullName ?? 'Agente Kaza';
    final priceNum = double.tryParse(_priceCtrl.text) ?? 0;
    
    final finalTitle = _titleCtrl.text.trim().isNotEmpty 
        ? _titleCtrl.text.trim() 
        : '$_propertyType en ${_addressCtrl.text}';

    String dbOperation = 'VENTA';
    if (_operationType == 'Alquilar') dbOperation = 'ALQUILER';
    if (_operationType == 'Dar en Anticrético') dbOperation = 'ANTICRETICO';

    bool inserted = false;
    try {
      await SupabaseConfig.client.rpc('fn_create_property', params: {
        'p_title': finalTitle,
        'p_property_type': _propertyType,
        'p_operation': dbOperation,
        'p_price': priceNum,
        'p_surface': int.tryParse(_builtCtrl.text) ?? 0,
        'p_rooms': int.tryParse(_bedroomsCtrl.text) ?? 0,
        'p_bathrooms': int.tryParse(_bathroomsCtrl.text) ?? 0,
        'p_latitude': _selectedLat,
        'p_longitude': _selectedLng,
        'p_owner_id': userId,
      });
      inserted = true;
    } catch (_) {}

    if (!inserted) {
      try {
        await SupabaseConfig.client.from('properties').insert({
          'title': finalTitle,
          'address_canonical': finalTitle,
          'property_type': _propertyType,
          'price_usd': priceNum,
          'total_surface_m2': int.tryParse(_builtCtrl.text) ?? 0,
          'rooms': int.tryParse(_bedroomsCtrl.text) ?? 0,
          'bathrooms': int.tryParse(_bathroomsCtrl.text) ?? 0,
          'status': 'PUBLISHED',
          'latitude': _selectedLat,
          'longitude': _selectedLng,
          'operation': dbOperation,
          'owner_id': userId,
        });
        inserted = true;
      } catch (e) {
        print('Error en fallback insert: $e');
      }
    }

    if (!inserted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la publicación en la base de datos.'),
            backgroundColor: KazaTheme.primaryCoral,
          ),
        );
      }
      return;
    }

    final newItem = PropertyMapItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalTitle,
      price: '$_currency ${_priceCtrl.text}',
      operation: dbOperation,
      type: _propertyType,
      location: LatLng(_selectedLat, _selectedLng),
      bedrooms: int.tryParse(_bedroomsCtrl.text) ?? 0,
      bathrooms: int.tryParse(_bathroomsCtrl.text) ?? 0,
      surface: '${_builtCtrl.text} m²',
      isPlus: true,
      trustLabel: agentName,
      isOrg: true,
    );

    ref.read(localPublishedPropertiesProvider.notifier).addProperty(newItem);
    ref.invalidate(mapPropertiesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Publicación creada! Ya aparece en el mapa.'),
          backgroundColor: Color(0xFF27AE60),
        ),
      );
      _resetForm();
      context.go('/map');
    }
  }

  void _resetForm() {
    _pageController.jumpToPage(0);
    setState(() {
      _currentPage = 0;
      _operationType = 'Vender';
      _propertyType = 'Departamento';
      _selectedLat = -17.7833;
      _selectedLng = -63.1821;
      _addressCtrl.text = 'Av. San Martín · Equipetrol';
      _terrainCtrl.text = '300';
      _builtCtrl.text = '180';
      _bedroomsCtrl.text = '3';
      _bathroomsCtrl.text = '3';
      _garageCtrl.text = '2';
      _floorCtrl.text = '3';
      _mediaItems = [];
      _currency = 'BOB';
      _priceCtrl.text = '850000';
      _consultarPrecio = false;
      _titleCtrl.text = 'Casa contemporánea con jardín y galería';
      _descCtrl.clear();
      _plusVideo = false;
      _plusPlano = false;
      _plus3D = false;
      _plusImagen = false;
      _msgKaza = true;
      _msgWhatsapp = true;
      _call = false;
      _precisionType = 'Zona aproximada';
    });
  }

  Future<void> _updateLocationAddress(double lat, double lng, {void Function(String name)? onAddressResolved}) async {
    if (!mounted) return;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'KazaApp/1.0 (com.kaza.app)'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final road = addr['road'] ?? addr['pedestrian'] ?? addr['street'] ?? addr['footway'] ?? addr['path'] ?? addr['suburb'] ?? '';
          final suburb = addr['suburb'] ?? addr['neighbourhood'] ?? addr['quarter'] ?? addr['city_district'] ?? addr['city'] ?? '';
          
          String formatted = '';
          if (road.toString().isNotEmpty && suburb.toString().isNotEmpty && road.toString() != suburb.toString()) {
            formatted = '${road.toString()} · ${suburb.toString()}';
          } else if (road.toString().isNotEmpty) {
            formatted = road.toString();
          } else if (suburb.toString().isNotEmpty) {
            formatted = suburb.toString();
          } else if (data['display_name'] != null) {
            final parts = (data['display_name'] as String).split(',');
            formatted = parts.take(2).join(',').trim();
          }

          if (formatted.isNotEmpty) {
            if (onAddressResolved != null) {
              onAddressResolved(formatted);
            } else if (mounted) {
              setState(() {
                _addressCtrl.text = formatted;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }

  void _openMapPickerModal() {
    double tempLat = _selectedLat;
    double tempLng = _selectedLng;
    String tempAddress = _addressCtrl.text;
    MapController modalMapCtrl = MapController();
    TextEditingController searchCtrl = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          void performSearch(String query) {
            if (debounce?.isActive ?? false) debounce!.cancel();
            debounce = Timer(const Duration(milliseconds: 400), () async {
              if (query.trim().length < 3) {
                setModal(() { searchResults = []; isSearching = false; });
                return;
              }
              setModal(() { isSearching = true; });
              try {
                final searchUrl = Uri.parse(
                  'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent("$query, Santa Cruz, Bolivia")}&limit=5&addressdetails=1',
                );
                final res = await http.get(searchUrl, headers: {'User-Agent': 'KazaApp/1.0 (com.kaza.app)'});
                if (res.statusCode == 200) {
                  final List data = jsonDecode(res.body);
                  setModal(() {
                    searchResults = data.map<Map<String, dynamic>>((item) => {
                      'display_name': item['display_name'],
                      'lat': double.parse(item['lat']),
                      'lon': double.parse(item['lon']),
                      'name': item['name'] ?? item['display_name'].toString().split(',')[0],
                    }).toList();
                    isSearching = false;
                  });
                }
              } catch (e) {
                setModal(() { isSearching = false; });
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: KazaTheme.coralKaza),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ubicación exacta',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.azulKaza)),
                            Text('Toca el mapa para colocar el PIN',
                                style: TextStyle(color: KazaTheme.grisMedio, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: KazaTheme.azulKaza),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: KazaTheme.grisClaro,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: KazaTheme.grisMedio),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: performSearch,
                            style: const TextStyle(fontSize: 13, color: KazaTheme.azulKaza),
                            decoration: const InputDecoration(
                              hintText: 'Buscar calle, avenida, barrio o zona',
                              hintStyle: TextStyle(color: KazaTheme.grisMedio, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (isSearching)
                          const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: KazaTheme.coralKaza),
                          ),
                      ],
                    ),
                  ),
                ),
                if (searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (ctx, i) {
                        final item = searchResults[i];
                        return ListTile(
                          dense: true,
                          title: Text(item['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(item['display_name'], style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            setModal(() {
                              tempLat = item['lat'];
                              tempLng = item['lon'];
                              tempAddress = item['name'];
                              searchResults = [];
                              searchCtrl.text = item['name'];
                            });
                            modalMapCtrl.move(LatLng(tempLat, tempLng), 16);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: modalMapCtrl,
                        options: MapOptions(
                          initialCenter: LatLng(tempLat, tempLng),
                          initialZoom: 15,
                          onTap: (_, point) {
                            setModal(() {
                              tempLat = point.latitude;
                              tempLng = point.longitude;
                            });
                            _updateLocationAddress(tempLat, tempLng, onAddressResolved: (resolvedName) {
                              setModal(() {
                                tempAddress = resolvedName;
                              });
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.kaza.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(tempLat, tempLng),
                                width: 44, height: 56,
                                child: CustomPaint(
                                  painter: KazaPinPainter(icon: Icons.location_on_rounded, isSelected: false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 12, left: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                          ),
                          child: Text(
                            '${tempLat.toStringAsFixed(4)}, ${tempLng.toStringAsFixed(4)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: KazaTheme.azulKaza),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tempAddress,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: KazaTheme.azulKaza, fontSize: 13)),
                      const Text('Mueve el pin para ajustar la ubicación. La dirección pública puede ser menor.',
                          style: TextStyle(color: KazaTheme.grisMedio, fontSize: 11)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KazaTheme.azulKaza,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedLat = tempLat;
                          _selectedLng = tempLng;
                          _addressCtrl.text = tempAddress;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Confirmar ubicación',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(kazaAuthProvider);
    final agentName = authState.fullName ?? 'Agente Kaza';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep5(), // Old step 5 (Plus options) becomes step 4
                  _buildStep6(agentName), // New step 5 (Review)
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    String stepTitle = 'Publicar';
    if (_currentPage == 2) stepTitle = 'Detalles';
    if (_currentPage == 4) stepTitle = 'Revisar y publicar';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _goBack,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_back, size: 22, color: KazaTheme.azulKaza),
                  ),
                ),
              Text(stepTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: KazaTheme.textPrimary)),
            ],
          ),
          Text('${_currentPage + 1}/$_totalPages',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KazaTheme.grisMedio)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _currentPage == _totalPages - 1;
    final isFirst = _currentPage == 0;
    
    String btnText = 'Continuar';
    if (_currentPage == 2) btnText = 'Guardar y continuar';
    if (isLast) btnText = 'Publicar';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFirst)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: KazaTheme.grisClaro, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('☁️ Guardado automáticamente', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),
                    GestureDetector(
                      onTap: () => context.go('/map'),
                      child: const Text('Salir', style: TextStyle(color: KazaTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentPage == 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: KazaTheme.grisClaro, borderRadius: BorderRadius.circular(10)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estados del borrador', style: TextStyle(color: KazaTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Guardando... Sin conexión, pendiente de sincronizar', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),
                    SizedBox(height: 4),
                    Text('Borrador recuperado', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: isLast ? _publish : _goNext,
              child: Text(
                btnText,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Propiedad',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: ['Venta', 'Alquiler', 'Anticrético'].map((op) {
              final sel = _operationType == op;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _operationType = op),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: sel ? KazaTheme.primaryCoralLight : KazaTheme.glassBorder, width: 1.5),
                    ),
                    child: Text(op,
                        style: TextStyle(
                            color: sel ? KazaTheme.primaryCoralLight : KazaTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Tipo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: ['Casa', 'Departamento'].map((type) {
              final sel = _propertyType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _propertyType = type),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: sel ? KazaTheme.primaryCoralLight : KazaTheme.glassBorder, width: 1.5),
                    ),
                    child: Text(type,
                        style: TextStyle(
                            color: sel ? KazaTheme.primaryCoralLight : KazaTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['Terreno', 'Local'].map((type) {
              final sel = _propertyType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _propertyType = type),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: sel ? KazaTheme.primaryCoralLight : KazaTheme.glassBorder, width: 1.5),
                    ),
                    child: Text(type,
                        style: TextStyle(
                            color: sel ? KazaTheme.primaryCoralLight : KazaTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KazaTheme.grisClaro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Posible coincidencia encontrada',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                const SizedBox(height: 8),
                const Text('Una Property existente parece coincidir por ubicación y características físicas.',
                    style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KazaTheme.primaryCoralLight,
                          side: const BorderSide(color: KazaTheme.primaryCoralLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Es la misma'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KazaTheme.textPrimary,
                          side: const BorderSide(color: KazaTheme.glassBorder),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('No es la misma'),
                      ),
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

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubicación',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _openMapPickerModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: KazaTheme.glassBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 18, color: KazaTheme.grisMedio),
                  SizedBox(width: 8),
                  Text('Buscar calle, barrio o zona',
                      style: TextStyle(color: KazaTheme.grisMedio, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTap: _openMapPickerModal,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(_selectedLat, _selectedLng),
                        initialZoom: 14,
                        onTap: (_, point) {
                          setState(() {
                            _selectedLat = point.latitude;
                            _selectedLng = point.longitude;
                          });
                          _updateLocationAddress(point.latitude, point.longitude);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.kaza.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_selectedLat, _selectedLng),
                              width: 44, height: 56,
                              child: CustomPaint(
                                painter: KazaPinPainter(icon: Icons.location_on_rounded, isSelected: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_location_alt, size: 14, color: KazaTheme.coralKaza),
                            SizedBox(width: 4),
                            Text('Editar PIN',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: KazaTheme.azulKaza)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: KazaTheme.grisClaro, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_addressCtrl.text,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: KazaTheme.azulKaza)),
                const Text('Mueve el pin para ajustar la ubicación. La dirección pública puede ser menor.',
                    style: TextStyle(color: KazaTheme.grisMedio, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Atributos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _specFieldNew('Superficie construida', '180 m²', _builtCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _specFieldNew('Terreno', '300 m²', _terrainCtrl)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _specFieldNew('Dormitorios', '3', _bedroomsCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _specFieldNew('Baños', '2', _bathroomsCtrl)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Título editorial',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Título', style: TextStyle(fontSize: 12, color: KazaTheme.textPrimary)),
          const SizedBox(height: 4),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 14, color: KazaTheme.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Separado de atributos y descripción.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),
          
          const SizedBox(height: 24),
          const Text('Descripción',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: KazaTheme.glassBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Espacios amplios, galería conectada al jardín...',
                    hintStyle: TextStyle(color: KazaTheme.textSecondary, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KazaTheme.textPrimary,
                      side: const BorderSide(color: KazaTheme.glassBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Ayuda con IA', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('IA propone - tu confirmas.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),

          const SizedBox(height: 24),
          const Text('Precio',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: ['BOB', 'USD', 'Consultar'].map((op) {
              final sel = (op == 'Consultar' && _consultarPrecio) || (op == _currency && !_consultarPrecio);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (op == 'Consultar') {
                        _consultarPrecio = true;
                      } else {
                        _consultarPrecio = false;
                        _currency = op;
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: sel ? KazaTheme.primaryCoralLight : KazaTheme.glassBorder, width: 1.5),
                    ),
                    child: Text(op,
                        style: TextStyle(
                            color: sel ? KazaTheme.primaryCoralLight : KazaTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Monto', style: TextStyle(fontSize: 12, color: KazaTheme.textPrimary)),
          const SizedBox(height: 4),
          TextField(
            controller: _priceCtrl,
            enabled: !_consultarPrecio,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, color: KazaTheme.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: _consultarPrecio ? KazaTheme.grisClaro : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Al elegir Consultar, Monto se oculta/desactiva.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),

          const SizedBox(height: 24),
          const Text('Media',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KazaTheme.grisClaro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 80,
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KazaTheme.glassBorder),
                        ),
                        child: Center(child: Text('Foto ${index + 1}', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 11))),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                const Text('Portada: Foto 1 • Mantén pulsado para reordenar', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                const Text('Docs sensibles no van aquí.', style: TextStyle(color: KazaTheme.primaryCoralLight, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Media IA (solo cuando aplique)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: KazaTheme.glassBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amoblado virtual - disclosure obligatorio', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                const Text('Ver original →', style: TextStyle(color: KazaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specFieldNew(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.textPrimary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 14, color: KazaTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: KazaTheme.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: KazaTheme.glassBorder)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _specField(String label, String? unit, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.grisMedio, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: KazaTheme.azulKaza),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: const TextStyle(color: KazaTheme.grisMedio, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: KazaTheme.grisClaro,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fotos + precio',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
          const SizedBox(height: 20),
          MediaPickerWidget(
            initialItems: _mediaItems,
            onChanged: (items) => setState(() => _mediaItems = items),
          ),
          const SizedBox(height: 24),
          const Text('Moneda',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KazaTheme.azulKaza)),
          const SizedBox(height: 10),
          Row(
            children: ['BOB', 'USD'].map((c) {
              final sel = _currency == c;
              return GestureDetector(
                onTap: () => setState(() => _currency = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? KazaTheme.azulKaza : KazaTheme.grisClaro,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(c,
                      style: TextStyle(
                          color: sel ? Colors.white : KazaTheme.azulKaza,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceCtrl,
            enabled: !_consultarPrecio,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: KazaTheme.azulKaza),
            decoration: InputDecoration(
              prefixText: '$_currency ',
              prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: KazaTheme.grisMedio),
              filled: true,
              fillColor: KazaTheme.grisClaro,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _consultarPrecio = !_consultarPrecio),
            child: Row(
              children: [
                Checkbox(
                  value: _consultarPrecio,
                  onChanged: (v) => setState(() => _consultarPrecio = v ?? false),
                  activeColor: KazaTheme.azulKaza,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const Text('Consultar precio',
                    style: TextStyle(color: KazaTheme.azulKaza, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Text('Monto o Consultar: excluyentes.',
              style: TextStyle(color: KazaTheme.grisMedio, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Presentación',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
          const SizedBox(height: 20),
          const Text('Descripción',
              style: TextStyle(fontSize: 13, color: KazaTheme.grisMedio, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            style: const TextStyle(color: KazaTheme.azulKaza, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe el inmueble...',
              hintStyle: const TextStyle(color: KazaTheme.grisMedio),
              filled: true,
              fillColor: KazaTheme.grisClaro,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Mejora la presentación',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.azulKaza)),
          const SizedBox(height: 12),
          ...[
            ['Video', Icons.videocam_rounded, _plusVideo],
            ['Plano', Icons.architecture_rounded, _plusPlano],
            ['Recorrido / 3D', Icons.view_in_ar_rounded, _plus3D],
            ['KAZA imagen', Icons.auto_awesome_rounded, _plusImagen],
          ].map((item) {
            final label = item[0] as String;
            final icon = item[1] as IconData;
            final active = item[2] as bool;
            return GestureDetector(
              onTap: () => setState(() {
                if (label == 'Video') _plusVideo = !_plusVideo;
                if (label == 'Plano') _plusPlano = !_plusPlano;
                if (label == 'Recorrido / 3D') _plus3D = !_plus3D;
                if (label == 'KAZA imagen') _plusImagen = !_plusImagen;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: active ? KazaTheme.azulKaza.withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? KazaTheme.azulKaza : KazaTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: active ? KazaTheme.azulKaza : KazaTheme.grisMedio),
                    const SizedBox(width: 10),
                    Text(label,
                        style: TextStyle(
                            color: active ? KazaTheme.azulKaza : KazaTheme.textSecondary,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: KazaTheme.coralKaza.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('PLUS',
                          style: TextStyle(color: KazaTheme.coralKaza, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                    if (active) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded, color: KazaTheme.azulKaza, size: 18),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text('Ahora no →',
              style: TextStyle(color: KazaTheme.grisMedio, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStep6(String agentName) {
    final priceText = _consultarPrecio
        ? 'Consultar'
        : '${_currency == 'BOB' ? 'Bs' : '\$'} ${_priceCtrl.text.isEmpty ? '—' : _priceCtrl.text}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Canales de contacto',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          _contactSwitch('Mensaje KAZA', _msgKaza, (val) => setState(() => _msgKaza = val)),
          const SizedBox(height: 8),
          _contactSwitch('WhatsApp', _msgWhatsapp, (val) => setState(() => _msgWhatsapp = val)),
          const SizedBox(height: 8),
          _contactSwitch('Llamar', _call, (val) => setState(() => _call = val)),
          const SizedBox(height: 4),
          const Text('Kaza Chat es obligatorio por seguridad.', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),

          const SizedBox(height: 24),
          const Text('Revisión',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          Column(
            children: [
              _reviewItem('Score de calidad KAZA: 85%'),
              const SizedBox(height: 8),
              _reviewItem('Validación de ubicación completada'),
              const SizedBox(height: 8),
              _reviewItem('Imágenes sin marcas de agua'),
            ],
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF4E4), // Light yellow
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ejemplo de validación de negocio',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                const SizedBox(height: 8),
                const Text('Esta propiedad será etiquetada como "Plus" porque el usuario tiene un plan activo.',
                    style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Así la verán',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KazaTheme.glassBorder),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 180, width: double.infinity,
                    color: KazaTheme.grisClaro,
                    child: Center(
                      child: Icon(
                          _mediaItems.isNotEmpty ? Icons.image_rounded : Icons.image_not_supported_rounded,
                          size: 48, color: KazaTheme.grisMedio),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_propertyType · $_operationType · ${_addressCtrl.text.split(',').first}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: KazaTheme.azulKaza)),
                      const SizedBox(height: 8),
                      Text(priceText,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: KazaTheme.textPrimary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _chip(Icons.straighten_rounded, '${_builtCtrl.text} m²'),
                          const SizedBox(width: 12),
                          _chip(Icons.bed_rounded, '${_bedroomsCtrl.text} dorm.'),
                          const SizedBox(width: 12),
                          _chip(Icons.bathtub_rounded, '${_bathroomsCtrl.text} baños'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: KazaTheme.glassBorder, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const CircleAvatar(
                              radius: 14,
                              backgroundColor: KazaTheme.primaryCoralLight,
                              child: Icon(Icons.person, size: 14, color: Colors.white)),
                          const SizedBox(width: 8),
                          Text(agentName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: KazaTheme.textPrimary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6)),
                            child: const Text('✓ Verificado',
                                style: TextStyle(color: Color(0xFF27AE60), fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _contactSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: KazaTheme.textPrimary)),
        Switch(
          value: value,
          onChanged: (label == 'Mensaje KAZA') ? null : onChanged,
          activeColor: Colors.white,
          activeTrackColor: KazaTheme.primaryCoralLight,
        ),
      ],
    );
  }

  Widget _reviewItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF27AE60), fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _chip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KazaTheme.grisMedio),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(fontSize: 12, color: KazaTheme.textSecondary, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _plusBadge(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: KazaTheme.coralKaza.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6)),
        child: Text('$label · PLUS',
            style: const TextStyle(color: KazaTheme.coralKaza, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}
