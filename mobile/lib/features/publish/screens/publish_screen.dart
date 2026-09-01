import 'dart:async';
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

/// ➕ PUBLICAR WIZARD B04 — 12 Pasos
class PublishScreen extends ConsumerStatefulWidget {
  const PublishScreen({super.key});
  @override
  ConsumerState<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends ConsumerState<PublishScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Datos del formulario
  String _operationType = '';
  String _propertyType = '';
  
  // Ubicación
  double _selectedLat = -17.7833;
  double _selectedLng = -63.1821;
  final _addressCtrl = TextEditingController();
  
  // Características
  final _terrainCtrl = TextEditingController();
  final _builtCtrl = TextEditingController();
  final _bedroomsCtrl = TextEditingController();
  final _bathroomsCtrl = TextEditingController();
  final _garageCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _totalFloorsCtrl = TextEditingController(text: '1');
  
  // Precio
  String _currency = 'USD';
  final _priceCtrl = TextEditingController();
  bool _consultarPrecio = false;
  
  // Fotos
  List<KazaMediaItem> _mediaItems = [];
  
  // Descripción
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  // Amenities
  final List<String> _selectedAmenities = [];
  final List<String> _popularAmenities = ['Piscina', 'Gimnasio', 'Sala de eventos', 'Seguridad 24/7', 'Parqueo visitas', 'Aire acondicionado', 'Balcón', 'Churrasquera', 'Cocina equipada'];
  
  // Anunciante
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  bool _showContact = true;
  
  bool _isPublishing = false;
  
  // Límites Free
  bool _isLoadingLimits = true;
  bool _hasReachedLimit = false;
  int _activeListingsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(kazaAuthProvider);
      if (auth.fullName != null) _contactNameCtrl.text = auth.fullName!;
      if (auth.userId != null) _contactPhoneCtrl.text = '+591 70000000'; // Mock phone for now
    });
    _checkLimits();
  }

  Future<void> _checkLimits() async {
    try {
      final auth = ref.read(kazaAuthProvider);
      final userId = auth.userId;
      if (userId == null) {
        if (mounted) setState(() => _isLoadingLimits = false);
        return;
      }
      
      final response = await SupabaseConfig.client
          .from('properties')
          .select('id')
          .eq('owner_id', userId)
          .eq('status', 'PUBLISHED');
          
      _activeListingsCount = (response as List).length;
      _hasReachedLimit = _activeListingsCount >= 2;
    } catch (e) {
      debugPrint('Error checking limits: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLimits = false);
    }
  }

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
    _ageCtrl.dispose();
    _totalFloorsCtrl.dispose();
    _priceCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage == 11) {
      context.go('/map'); // Go to map after success
      return;
    }
    
    // Validations per step
    if (_currentPage == 1 && _operationType.isEmpty) return _showError('Selecciona el tipo de operación');
    if (_currentPage == 2 && _propertyType.isEmpty) return _showError('Selecciona el tipo de propiedad');
    if (_currentPage == 5 && !_consultarPrecio && _priceCtrl.text.isEmpty) return _showError('Ingresa un precio');
    
    if (_currentPage == 10) {
      _publish();
      return;
    }

    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _goBack() {
    if (_currentPage > 0 && _currentPage < 11) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentPage == 0) {
      context.go('/map');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: KazaTheme.semanticError));
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    try {
      final authState = ref.read(kazaAuthProvider);
      final userId = authState.userId;
      
      final priceNum = double.tryParse(_priceCtrl.text) ?? 0;
      final finalTitle = _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : '$_propertyType en ${_addressCtrl.text}';

      String dbOperation = 'VENTA';
      if (_operationType == 'Alquiler') dbOperation = 'ALQUILER';
      if (_operationType == 'Anticrético') dbOperation = 'ANTICRETICO';
      if (_operationType == 'Alquiler temporal') dbOperation = 'TEMPORAL';

      final photosList = _mediaItems.map((m) => m.path).toList(); // En un caso real subiríamos a Storage primero

      final propertyData = {
        'title': finalTitle,
        'address_canonical': _addressCtrl.text,
        'property_type': _propertyType,
        'price_usd': priceNum,
        'currency_code': _currency,
        'total_surface_m2': int.tryParse(_terrainCtrl.text) ?? 0,
        'covered_surface_m2': int.tryParse(_builtCtrl.text) ?? 0,
        'rooms': int.tryParse(_bedroomsCtrl.text) ?? 0,
        'bathrooms': int.tryParse(_bathroomsCtrl.text) ?? 0,
        'parking_spaces': int.tryParse(_garageCtrl.text) ?? 0,
        'age_years': int.tryParse(_ageCtrl.text) ?? 0,
        'floors_total': int.tryParse(_totalFloorsCtrl.text) ?? 1,
        'status': 'PUBLISHED',
        'latitude': _selectedLat,
        'longitude': _selectedLng,
        'operation': dbOperation,
        'owner_id': userId,
        'description': _descCtrl.text,
        'amenities': _selectedAmenities,
        'photos': photosList,
        'contact_name': _contactNameCtrl.text,
        'contact_phone': _contactPhoneCtrl.text,
      };

      await SupabaseConfig.client.from('properties').insert(propertyData);

      ref.invalidate(mapPropertiesProvider);
      
      // Redirigir directamente al mapa después de publicar exitosamente
      if (mounted) context.go('/map');
    } catch (e) {
      _showError('Error al publicar: $e');
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLimits) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: KazaTheme.azulKaza)),
      );
    }

    if (_hasReachedLimit) {
      return _buildLimitReachedScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < 11) _buildTopBar(),
            if (_currentPage < 11) _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildStep01Inicio(),
                  _buildStep02Operacion(),
                  _buildStep03Tipo(),
                  _buildStep04Ubicacion(),
                  _buildStep05Caracteristicas(),
                  _buildStep06Precio(),
                  _buildStep07Fotos(),
                  _buildStep08Descripcion(),
                  _buildStep09Amenities(),
                  _buildStep10Anunciante(),
                  _buildStep11Revision(),
                  _buildStep12Exito(),
                ],
              ),
            ),
            if (_currentPage < 11) _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitReachedScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: KazaTheme.azulKaza),
          onPressed: () => context.go('/map'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 80, color: KazaTheme.semanticError),
              const SizedBox(height: 24),
              const Text(
                'Límite Free Alcanzado',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
              ),
              const SizedBox(height: 12),
              const Text(
                'Has alcanzado el límite de 2 publicaciones activas de tu plan gratuito. Mejora a Plus para publicar ilimitadamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: KazaTheme.textSecondary, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KazaTheme.accentGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suscripciones próximamente...')));
                  },
                  child: const Text('Mejorar a Plus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/map'),
                child: const Text('Volver al mapa', style: TextStyle(color: KazaTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _goBack,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_back, size: 24, color: KazaTheme.azulKaza),
                ),
              ),
              const Text('Publicar propiedad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
            ],
          ),
          const Icon(Icons.person_outline, color: KazaTheme.azulKaza),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(11, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 10 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? KazaTheme.azulKaza : KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KazaTheme.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isPublishing ? null : _goNext,
              child: _isPublishing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentPage == 10 ? 'Publicar ahora' : 'Continuar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/map'),
            child: const Text('Guardar borrador', style: TextStyle(color: KazaTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEPS BUILDERS
  // ─────────────────────────────────────────────────────────────────────────
  
  Widget _buildStep01Inicio() {
    return _stepContainer('01', 'Inicio', 'Elige qué quieres publicar.', [
      _selectionCard('Publicar nueva propiedad', 'Crear un nuevo anuncio desde cero', Icons.add, true, () => _goNext()),
      const SizedBox(height: 16),
      _selectionCard('Republicar', 'Usar una publicación anterior', Icons.refresh, false, () {}),
    ]);
  }

  Widget _buildStep02Operacion() {
    final ops = ['Venta', 'Alquiler', 'Alquiler temporal', 'Anticrético'];
    return _stepContainer('02', 'Tipo de operación', 'Define el tipo de operación.', ops.map((op) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _selectionCard(op, 'Publica para ${op.toLowerCase()}', Icons.sell_outlined, _operationType == op, () {
          setState(() => _operationType = op);
        }),
      );
    }).toList());
  }

  Widget _buildStep03Tipo() {
    final tipos = [
      {'label': 'Departamento', 'icon': Icons.apartment},
      {'label': 'Casa', 'icon': Icons.home_outlined},
      {'label': 'Oficina', 'icon': Icons.business},
      {'label': 'Terreno', 'icon': Icons.landscape},
      {'label': 'Local', 'icon': Icons.storefront},
      {'label': 'Galpón', 'icon': Icons.warehouse},
      {'label': 'Parqueo', 'icon': Icons.local_parking},
      {'label': 'Otro', 'icon': Icons.category},
    ];
    return _stepContainer('03', 'Tipo de propiedad', 'Selecciona el tipo de propiedad.', [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: tipos.length,
        itemBuilder: (ctx, i) {
          final t = tipos[i];
          final isSel = _propertyType == t['label'];
          return GestureDetector(
            onTap: () => setState(() => _propertyType = t['label'] as String),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: isSel ? KazaTheme.azulKaza : KazaTheme.glassBorder, width: isSel ? 2 : 1),
                borderRadius: BorderRadius.circular(12),
                color: isSel ? KazaTheme.azulKaza.withValues(alpha: 0.05) : Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t['icon'] as IconData, color: isSel ? KazaTheme.azulKaza : KazaTheme.textSecondary, size: 32),
                  const SizedBox(height: 8),
                  Text(t['label'] as String, style: TextStyle(color: isSel ? KazaTheme.azulKaza : KazaTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildStep04Ubicacion() {
    return _stepContainer('04', 'Ubicación', 'Indica la ubicación exacta.', [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: KazaTheme.grisClaro, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.search, color: KazaTheme.grisMedio),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(hintText: 'Buscar dirección o lugar', border: InputBorder.none, isDense: true),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        height: 200,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: KazaTheme.grisClaro),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_selectedLat, _selectedLng),
                initialZoom: 14,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLat = point.latitude;
                    _selectedLng = point.longitude;
                  });
                },
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.kaza.app'),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_selectedLat, _selectedLng),
                    width: 44,
                    height: 56,
                    child: CustomPaint(painter: KazaPinPainter(icon: Icons.location_on, isSelected: true)),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildStep05Caracteristicas() {
    return _stepContainer('05', 'Características', 'Agrega los detalles principales.', [
      _numberInput('Área total (m²)', _terrainCtrl),
      _numberInput('Área construida (m²)', _builtCtrl),
      _numberInput('Dormitorios', _bedroomsCtrl),
      _numberInput('Baños', _bathroomsCtrl),
      _numberInput('Parqueos', _garageCtrl),
      _numberInput('Antigüedad (años)', _ageCtrl),
      _numberInput('Piso', _floorCtrl),
    ]);
  }

  Widget _buildStep06Precio() {
    return _stepContainer('06', 'Precio', 'Define el precio y condiciones.', [
      Row(
        children: [
          DropdownButton<String>(
            value: _currency,
            items: ['USD', 'BOB'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _currency = v!),
            underline: const SizedBox(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
              decoration: const InputDecoration(hintText: 'Ej. 125000', border: UnderlineInputBorder()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      SwitchListTile(
        title: const Text('Precio negociable', style: TextStyle(fontWeight: FontWeight.w600)),
        value: _consultarPrecio,
        onChanged: (v) => setState(() => _consultarPrecio = v),
        activeColor: KazaTheme.primaryCoral,
        contentPadding: EdgeInsets.zero,
      ),
    ]);
  }

  Widget _buildStep07Fotos() {
    return _stepContainer('07', 'Fotos', 'Sube fotos de alta calidad.', [
      MediaPickerWidget(
        initialItems: _mediaItems,
        onChanged: (items) => setState(() => _mediaItems = items),
      ),
    ]);
  }

  Widget _buildStep08Descripcion() {
    return _stepContainer('08', 'Descripción', 'Cuenta lo mejor de tu propiedad.', [
      TextField(
        controller: _titleCtrl,
        maxLength: 60,
        decoration: const InputDecoration(labelText: 'Título de la publicación', hintText: 'Ej. Moderno departamento...'),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _descCtrl,
        maxLines: 6,
        maxLength: 1000,
        decoration: const InputDecoration(labelText: 'Descripción detallada', hintText: 'Describe los ambientes, acabados, entorno...', alignLabelWithHint: true),
      ),
    ]);
  }

  Widget _buildStep09Amenities() {
    return _stepContainer('09', 'Amenities', 'Selecciona las amenidades.', [
      const Text('Populares', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _popularAmenities.map((am) {
          final isSel = _selectedAmenities.contains(am);
          return FilterChip(
            label: Text(am),
            selected: isSel,
            onSelected: (val) {
              setState(() {
                if (val) {
                  _selectedAmenities.add(am);
                } else {
                  _selectedAmenities.remove(am);
                }
              });
            },
            selectedColor: KazaTheme.azulKaza.withValues(alpha: 0.1),
            checkmarkColor: KazaTheme.azulKaza,
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildStep10Anunciante() {
    return _stepContainer('10', 'Anunciante', 'Quién publica y cómo contactarlo.', [
      TextField(controller: _contactNameCtrl, decoration: const InputDecoration(labelText: 'Nombre de contacto', prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 16),
      TextField(controller: _contactPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp', prefixIcon: Icon(Icons.phone_outlined))),
      const SizedBox(height: 24),
      SwitchListTile(
        title: const Text('Mostrar contacto', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Los interesados verán tu contacto'),
        value: _showContact,
        onChanged: (v) => setState(() => _showContact = v),
        activeColor: KazaTheme.primaryCoral,
        contentPadding: EdgeInsets.zero,
      ),
    ]);
  }

  Widget _buildStep11Revision() {
    return _stepContainer('11', 'Revisión', 'Revisa y confirma tu publicación.', [
      _reviewRow('Operación', _operationType),
      _reviewRow('Propiedad', _propertyType),
      _reviewRow('Precio', '$_currency ${_priceCtrl.text}'),
      _reviewRow('Ubicación', _addressCtrl.text.isNotEmpty ? _addressCtrl.text : 'Lat: $_selectedLat, Lng: $_selectedLng'),
      _reviewRow('Superficie', '${_terrainCtrl.text} m²'),
      _reviewRow('Dorm/Baños', '${_bedroomsCtrl.text} dorm - ${_bathroomsCtrl.text} baños'),
      _reviewRow('Fotos', '${_mediaItems.length} agregadas'),
      _reviewRow('Contacto', '${_contactNameCtrl.text} (${_contactPhoneCtrl.text})'),
    ]);
  }

  Widget _buildStep12Exito() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: KazaTheme.semanticSuccess),
            const SizedBox(height: 24),
            const Text('¡Publicación enviada!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
            const SizedBox(height: 12),
            const Text('Tu propiedad está en revisión.\nTe notificaremos cuando esté activa.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: KazaTheme.textSecondary)),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: KazaTheme.azulKaza, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => context.go('/profile'),
                child: const Text('Ver mis publicaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/map'),
              child: const Text('Volver al mapa', style: TextStyle(color: KazaTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMMONS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _stepContainer(String number, String title, String subtitle, List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(number, style: const TextStyle(color: KazaTheme.primaryCoral, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: KazaTheme.azulKaza, fontSize: 24, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _selectionCard(String title, String subtitle, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? KazaTheme.azulKaza : KazaTheme.glassBorder, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? KazaTheme.azulKaza.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? KazaTheme.azulKaza : KazaTheme.grisMedio, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? KazaTheme.azulKaza : KazaTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: KazaTheme.azulKaza),
          ],
        ),
      ),
    );
  }

  Widget _numberInput(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KazaTheme.textPrimary)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                int val = int.tryParse(ctrl.text) ?? 0;
                if (val > 0) ctrl.text = (val - 1).toString();
              }),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: ctrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
                int val = int.tryParse(ctrl.text) ?? 0;
                ctrl.text = (val + 1).toString();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(color: KazaTheme.azulKaza, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
