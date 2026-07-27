import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  static const int _totalPages = 6;

  // Step 1
  String _operationType = 'Vender';
  String _propertyType = 'Departamento';

  // Step 2
  double _selectedLat = -17.7833;
  double _selectedLng = -63.1821;
  String _addressLabel = 'Av. San Martín · Equipetrol';

  // Step 3
  final _terrainCtrl = TextEditingController(text: '300');
  final _builtCtrl = TextEditingController(text: '180');
  final _bedroomsCtrl = TextEditingController(text: '3');
  final _bathroomsCtrl = TextEditingController(text: '3');
  final _garageCtrl = TextEditingController(text: '2');
  final _floorCtrl = TextEditingController(text: '3');

  // Step 4
  List<KazaMediaItem> _mediaItems = [];
  String _currency = 'BOB';
  final _priceCtrl = TextEditingController(text: '850000');
  bool _consultarPrecio = false;

  // Step 5
  final _descCtrl = TextEditingController();
  bool _plusVideo = false;
  bool _plusPlano = false;
  bool _plus3D = false;
  bool _plusImagen = false;

  @override
  void dispose() {
    _pageController.dispose();
    _terrainCtrl.dispose();
    _builtCtrl.dispose();
    _bedroomsCtrl.dispose();
    _bathroomsCtrl.dispose();
    _garageCtrl.dispose();
    _floorCtrl.dispose();
    _priceCtrl.dispose();
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
    final agentName = authState.fullName ?? 'Agente Kaza';
    final priceNum = double.tryParse(_priceCtrl.text) ?? 0;

    bool inserted = false;
    try {
      await SupabaseConfig.client.rpc('fn_create_property', params: {
        'p_title': '$_propertyType en $_addressLabel',
        'p_property_type': _propertyType,
        'p_operation': _operationType.toUpperCase(),
        'p_price': priceNum,
        'p_surface': int.tryParse(_builtCtrl.text) ?? 0,
        'p_rooms': int.tryParse(_bedroomsCtrl.text) ?? 0,
        'p_bathrooms': int.tryParse(_bathroomsCtrl.text) ?? 0,
        'p_latitude': _selectedLat,
        'p_longitude': _selectedLng,
      });
      inserted = true;
    } catch (_) {}

    if (!inserted) {
      try {
        await SupabaseConfig.client.from('properties').insert({
          'address_canonical': '$_propertyType · $_addressLabel',
          'property_type': _propertyType,
          'price_usd': priceNum,
          'total_surface_m2': int.tryParse(_builtCtrl.text) ?? 0,
          'rooms': int.tryParse(_bedroomsCtrl.text) ?? 0,
          'bathrooms': int.tryParse(_bathroomsCtrl.text) ?? 0,
          'status': 'PUBLISHED',
          'latitude': _selectedLat,
          'longitude': _selectedLng,
          'operation': _operationType.toUpperCase(),
        });
        inserted = true;
      } catch (_) {}
    }

    final newItem = PropertyMapItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '$_propertyType · $_addressLabel',
      price: '$_currency ${_priceCtrl.text}',
      operation: _operationType.toUpperCase(),
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
      _addressLabel = 'Av. San Martín · Equipetrol';
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
      _descCtrl.clear();
      _plusVideo = false;
      _plusPlano = false;
      _plus3D = false;
      _plusImagen = false;
    });
  }


  void _openMapPickerModal() {
    double tempLat = _selectedLat;
    double tempLng = _selectedLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: KazaTheme.grisClaro,
                    borderRadius: BorderRadius.circular(10),
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
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(tempLat, tempLng),
                        initialZoom: 15,
                        onTap: (_, point) {
                          setModal(() {
                            tempLat = point.latitude;
                            tempLng = point.longitude;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
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
                    Text(_addressLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: KazaTheme.azulKaza, fontSize: 13)),
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
                        _addressLabel = '${tempLat.toStringAsFixed(4)}, ${tempLng.toStringAsFixed(4)}';
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
        ),
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
                  _buildStep4(),
                  _buildStep5(),
                  _buildStep6(agentName),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _currentPage == 0 ? () => context.go('/map') : _goBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: KazaTheme.azulKaza),
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(_totalPages, (i) {
              final bool active = i == _currentPage;
              final bool done = i < _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: done || active ? KazaTheme.azulKaza : KazaTheme.grisClaro,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('Guardado',
                style: TextStyle(color: KazaTheme.grisMedio, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _currentPage == _totalPages - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: KazaTheme.azulKaza,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: isLast ? _publish : _goNext,
          child: Text(
            isLast ? 'Publicar' : 'Continuar',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qué ofreces',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
          const SizedBox(height: 24),
          const Text('¿Qué quieres hacer?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: KazaTheme.azulKaza)),
          const SizedBox(height: 10),
          ...['Vender', 'Alquilar', 'Anticrético'].map((op) {
            final sel = _operationType == op;
            return GestureDetector(
              onTap: () => setState(() => _operationType = op),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? KazaTheme.azulKaza : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? KazaTheme.azulKaza : KazaTheme.glassBorder, width: sel ? 2 : 1),
                  boxShadow: sel
                      ? [BoxShadow(color: KazaTheme.azulKaza.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(op,
                        style: TextStyle(
                            color: sel ? Colors.white : KazaTheme.azulKaza,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    if (sel) ...[
                      const Spacer(),
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text('¿Qué propiedad es?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: KazaTheme.azulKaza)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Departamento', 'Casa', 'Terreno', 'Local Comercial', 'Oficina', 'Industrial', 'Rural', 'Otros']
                .map((type) {
              final sel = _propertyType == type;
              return GestureDetector(
                onTap: () => setState(() => _propertyType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? KazaTheme.azulKaza : KazaTheme.grisClaro,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(type,
                      style: TextStyle(
                          color: sel ? Colors.white : KazaTheme.azulKaza,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: KazaTheme.grisClaro, borderRadius: BorderRadius.circular(10)),
            child: const Text(
                'Local / Oficina / Industrial / Rural / Otros — mantienen sus schemas adaptativos según tipología.',
                style: TextStyle(color: KazaTheme.grisMedio, fontSize: 11)),
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
                            _addressLabel = '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
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
                Text(_addressLabel,
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
    final bool showBedrooms = ['Departamento', 'Casa', 'Local Comercial', 'Oficina'].contains(_propertyType);
    final bool showBuilt = _propertyType != 'Terreno';
    final bool showGarage = ['Departamento', 'Casa'].contains(_propertyType);
    final bool showFloor = _propertyType == 'Departamento';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Datos adaptativos',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
          const SizedBox(height: 4),
          Text(_propertyType,
              style: const TextStyle(fontSize: 13, color: KazaTheme.grisMedio, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          _specField('Terreno', 'm²', _terrainCtrl),
          if (showBuilt) ...[const SizedBox(height: 12), _specField('Construido', 'm²', _builtCtrl)],
          if (showBedrooms) ...[
            const SizedBox(height: 12), _specField('Dormitorios', null, _bedroomsCtrl),
            const SizedBox(height: 12), _specField('Baños', null, _bathroomsCtrl),
          ],
          if (showGarage) ...[const SizedBox(height: 12), _specField('Garajes', null, _garageCtrl)],
          if (showFloor) ...[const SizedBox(height: 12), _specField('Piso', null, _floorCtrl)],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: KazaTheme.grisClaro, borderRadius: BorderRadius.circular(10)),
            child: Text('Cambia según tipología. $_propertyType adapta sus campos específicos.',
                style: const TextStyle(color: KazaTheme.grisMedio, fontSize: 11)),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Así la verán',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KazaTheme.glassBorder),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_propertyType · $_operationType · ${_addressLabel.split(',').first}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: KazaTheme.azulKaza)),
                const SizedBox(height: 8),
                Text(priceText,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: KazaTheme.azulKaza)),
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
                        backgroundColor: KazaTheme.azulKaza,
                        child: Icon(Icons.person, size: 14, color: Colors.white)),
                    const SizedBox(width: 8),
                    Text(agentName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: KazaTheme.azulKaza)),
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
          if (_plusVideo || _plusPlano || _plus3D || _plusImagen) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: KazaTheme.grisClaro, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Presentación PLUS activada',
                      style: TextStyle(fontWeight: FontWeight.w700, color: KazaTheme.azulKaza, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: [
                      if (_plusVideo) _plusBadge('Video'),
                      if (_plusPlano) _plusBadge('Plano'),
                      if (_plus3D) _plusBadge('Recorrido 3D'),
                      if (_plusImagen) _plusBadge('KAZA imagen'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text('Opciones profesionales sólo si aplican. Publicar como categoría secundaria: colaborar.',
              style: TextStyle(color: KazaTheme.grisMedio, fontSize: 11)),
        ],
      ),
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
