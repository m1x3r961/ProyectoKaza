import 'dart:ui' as ui;
import '../../../core/network/api_client.dart';
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final MapController _mapController = MapController();
  bool _isSearchingLocation = false;

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
  final List<String> _popularAmenities = [
    'Piscina',
    'Gimnasio',
    'Sala de eventos',
    'Seguridad 24/7',
    'Parqueo visitas',
    'Aire acondicionado',
    'Balcón',
    'Churrasquera',
    'Cocina equipada'
  ];

  // Anunciante
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  bool _showContact = true;

  bool _isPublishing = false;
  Timer? _draftTimer;
  Future<void> _draftWrites = Future.value();
  bool _published = false;
  String _draftId = ApiClient.newId();
  String _requestKey = ApiClient.newId();
  String? _lastPayload;
  bool _draftReady = false;
  String? _draftError;
  final List<String> _uploadedPhotos = [];
  final Set<KazaMediaItem> _uploadedItems = {};
  List<TextEditingController> get _draftControllers => [
        _addressCtrl,
        _terrainCtrl,
        _builtCtrl,
        _bedroomsCtrl,
        _bathroomsCtrl,
        _garageCtrl,
        _floorCtrl,
        _ageCtrl,
        _totalFloorsCtrl,
        _priceCtrl,
        _titleCtrl,
        _descCtrl,
        _contactNameCtrl,
        _contactPhoneCtrl
      ];
  Map<String, dynamic> _draftPayload() => {
        'fields': _draftControllers.map((c) => c.text).toList(),
        'operation': _operationType,
        'type': _propertyType,
        'lat': _selectedLat,
        'lng': _selectedLng,
        'currency': _currency,
        'contactForPrice': _consultarPrecio,
        'showContact': _showContact,
        'amenities': _selectedAmenities,
        'photos': _uploadedPhotos,
        'requestKey': _requestKey,
        'lastPayload': _lastPayload
      };
  Future<void> _restoreDraft() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      if (mounted)
        setState(() => _draftError =
            'Iniciá sesión para guardar y recuperar tu borrador.');
      return;
    }
    try {
      final rows = await SupabaseConfig.client
          .from('listing_drafts')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false)
          .limit(1);
      if (!mounted) return;
      if (rows.isNotEmpty) {
        final row = rows.first;
        final d = Map<String, dynamic>.from(row['payload']);
        _draftId = row['id'];
        final fields = List<String>.from(d['fields'] ?? []);
        for (var i = 0;
            i < fields.length && i < _draftControllers.length;
            i++) {
          _draftControllers[i].text = fields[i];
        }
        _operationType = d['operation'] ?? '';
        _propertyType = d['type'] ?? '';
        _selectedLat = (d['lat'] as num?)?.toDouble() ?? _selectedLat;
        _selectedLng = (d['lng'] as num?)?.toDouble() ?? _selectedLng;
        _currency = d['currency'] ?? 'USD';
        _consultarPrecio = d['contactForPrice'] ?? false;
        _showContact = d['showContact'] ?? false;
        _selectedAmenities.addAll(List<String>.from(d['amenities'] ?? []));
        _uploadedPhotos.addAll(List<String>.from(d['photos'] ?? []));
        _requestKey = d['requestKey'] ?? ApiClient.newId();
        _lastPayload = d['lastPayload'];
      }
      _draftReady = true;
      setState(() {});
    } catch (_) {
      if (mounted)
        setState(() => _draftError =
            'No se pudo recuperar el borrador. Reintenta antes de editar.');
    }
  }

  void _scheduleDraft() {
    if (!_draftReady || _isPublishing) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 700), () => _saveDraft());
  }

  Future<void> _saveDraft() {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null || !_draftReady || _published) return Future.value();
    final snapshot = jsonDecode(jsonEncode(_draftPayload()));
    final draftId = _draftId;
    _draftWrites = _draftWrites.then((_) async {
      if (_published) return;
      try {
        await SupabaseConfig.client.from('listing_drafts').upsert({
          'id': draftId,
          'user_id': user.id,
          'payload': snapshot,
          'updated_at': DateTime.now().toUtc().toIso8601String()
        });
        _draftError = null;
      } catch (_) {
        _draftError =
            'No se pudo guardar el borrador. Conservá esta pantalla y reintentá.';
      }
      if (mounted) setState(() {});
    });
    return _draftWrites;
  }

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
    });
    _checkLimits();
    _restoreDraft();
    for (final controller in _draftControllers) {
      controller.addListener(_scheduleDraft);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearchingLocation = true);
    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=1'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          setState(() {
            _selectedLat = lat;
            _selectedLng = lon;
          });
          _mapController.move(LatLng(lat, lon), 15.0);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ubicación no encontrada')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error buscando ubicación: $e');
    } finally {
      if (mounted) setState(() => _isSearchingLocation = false);
    }
  }

  Future<void> _checkLimits() async {
    try {
      final auth = ref.read(kazaAuthProvider);
      final userId = auth.userId;
      if (userId == null) {
        if (mounted) setState(() => _isLoadingLimits = false);
        return;
      }

      // Only server-issued entitlements can authorize a limit; legacy profile tiers are untrusted.
      final limits = await ApiClient().request('/api/listings/limits');
      _activeListingsCount = limits['active'] as int;
      _hasReachedLimit = limits['limit'] != null &&
          _activeListingsCount >= (limits['limit'] as int);
    } catch (e) {
      debugPrint('Error checking limits: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLimits = false);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_published && !_isPublishing) _saveDraft();
    for (final controller in _draftControllers) {
      controller.removeListener(_scheduleDraft);
    }
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
    _scheduleDraft();
    if (_currentPage == 11) {
      context.go('/map'); // Go to map after success
      return;
    }

    // Validations per step
    if (_currentPage == 1 && _operationType.isEmpty)
      return _showError('Selecciona el tipo de operación');
    if (_currentPage == 2 && _propertyType.isEmpty)
      return _showError('Selecciona el tipo de propiedad');
    if (_currentPage == 5 && !_consultarPrecio && _priceCtrl.text.isEmpty)
      return _showError('Ingresa un precio');

    if (_currentPage == 10) {
      _publish();
      return;
    }

    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _goBack() {
    if (_currentPage > 0 && _currentPage < 11) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentPage == 0) {
      context.go('/map');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: KazaTheme.semanticError));
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    if (!_draftReady)
      return _showError('Primero recuperá el borrador o iniciá sesión.');
    _draftTimer?.cancel();
    setState(() => _isPublishing = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw ApiException('Inicia sesión para publicar.', 401);
      for (var i = 0; i < _mediaItems.length; i++) {
        final item = _mediaItems[i];
        if (item.bytes == null || _uploadedItems.contains(item)) continue;
        if (item.bytes!.length > 10 * 1024 * 1024)
          throw ApiException('Cada imagen debe pesar menos de 10 MB.', 400);
        // Decode and re-encode: strips EXIF (including exact GPS) and caps dimensions.
        final codec = await ui.instantiateImageCodec(item.bytes!,
            targetWidth: 1600, allowUpscaling: false);
        final frame = await codec.getNextFrame();
        final encoded =
            await frame.image.toByteData(format: ui.ImageByteFormat.png);
        frame.image.dispose();
        codec.dispose();
        if (encoded == null)
          throw ApiException('No se pudo procesar la imagen.', 400);
        final bytes = encoded.buffer.asUint8List();
        final prefix = item.mediaType == KazaMediaType.tour360 ? '360_' : '';
        final path = '${user.id}/$_draftId/$prefix${ApiClient.newId()}.png';
        await SupabaseConfig.client.storage
            .from('property-photos')
            .uploadBinary(path, bytes,
                fileOptions: const FileOptions(contentType: 'image/png'));
        _uploadedPhotos.add(SupabaseConfig.client.storage
            .from('property-photos')
            .getPublicUrl(path));
        _uploadedItems.add(item);
        // Persist successful uploads before the database publication, so retries can reuse them.
        await _saveDraft();
      }
      _mediaItems = [];
      final payload = <String, dynamic>{
        'title': _titleCtrl.text.trim().isEmpty
            ? '$_propertyType en la zona seleccionada'
            : _titleCtrl.text.trim(),
        'description': _descCtrl.text,
        'propertyType': _propertyType,
        'address': _addressCtrl.text,
        'operationType': _operationType == 'Anticrético'
            ? 'ANTICRETICO'
            : _operationType.startsWith('Alquiler')
                ? 'RENT'
                : 'SALE',
        'priceOriginal': double.tryParse(_priceCtrl.text) ?? 0,
        'currencyOriginal': _currency,
        'contactForPrice': _consultarPrecio,
        'latitude': _selectedLat,
        'longitude': _selectedLng,
        'countryCode': 'BOL',
        'cityId': 'santa_cruz',
        'totalSurfaceM2': double.tryParse(_terrainCtrl.text) ?? 0,
        'coveredSurfaceM2': double.tryParse(_builtCtrl.text) ?? 0,
        'rooms': int.tryParse(_bedroomsCtrl.text) ?? 0,
        'bathrooms': int.tryParse(_bathroomsCtrl.text) ?? 0,
        'parkingSpaces': int.tryParse(_garageCtrl.text) ?? 0,
        'ageYears': int.tryParse(_ageCtrl.text) ?? 0,
        'floorsTotal': int.tryParse(_totalFloorsCtrl.text) ?? 1,
        'photos': _uploadedPhotos,
        'amenities': _selectedAmenities,
        'contactName': _contactNameCtrl.text,
        'contactPhone': _contactPhoneCtrl.text,
        'showContact': _showContact,
      };
      final serialized = jsonEncode(payload);
      if (_lastPayload != null && _lastPayload != serialized)
        _requestKey = ApiClient.newId();
      _lastPayload = serialized;
      await _saveDraft();
      if (_draftError != null) throw ApiException(_draftError!, 503);
      await ApiClient().request('/api/listings',
          method: 'POST', body: payload, key: _requestKey);
      _published = true;
      await _draftWrites;
      try {
        await SupabaseConfig.client
            .from('listing_drafts')
            .delete()
            .eq('id', _draftId);
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Publicación confirmada. No pudimos limpiar el borrador; el reintento conserva la misma referencia.')));
      }
      ref.invalidate(mapPropertiesProvider);
      if (mounted) context.go('/map');
    } catch (e) {
      if (mounted)
        _showError(e is ApiException
            ? e.message
            : 'No se pudo publicar. Tu borrador conserva los datos guardados.');
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_draftError != null && !_draftReady) {
      return Scaffold(
          appBar: AppBar(title: const Text('Publicar')),
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_draftError!),
            TextButton(
                onPressed: () {
                  checkProgressiveAuth(
                      context: context,
                      ref: ref,
                      actionName: 'publicar',
                      onAuthenticatedAction: () {
                        _restoreDraft();
                        _checkLimits();
                      });
                },
                child: const Text('Continuar'))
          ])));
    }
    if (_isLoadingLimits) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body:
            Center(child: CircularProgressIndicator(color: KazaTheme.azulKaza)),
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
            if (_uploadedPhotos.isNotEmpty)
              Text('${_uploadedPhotos.length} fotos guardadas en el borrador'),
            if (_draftError != null)
              Text(_draftError!, style: const TextStyle(color: Colors.red)),
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
              const Icon(Icons.lock_outline_rounded,
                  size: 80, color: KazaTheme.semanticError),
              const SizedBox(height: 24),
              const Text(
                'Límite Free Alcanzado',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: KazaTheme.azulKaza),
              ),
              const SizedBox(height: 12),
              const Text(
                'Has alcanzado el límite de 2 publicaciones activas de tu plan gratuito. Mejora a Plus para publicar ilimitadamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: KazaTheme.textSecondary, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KazaTheme.accentGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Suscripciones próximamente...')));
                  },
                  child: const Text('Mejorar a Plus',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/map'),
                child: const Text('Volver al mapa',
                    style: TextStyle(
                        color: KazaTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
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
                  child: Icon(Icons.arrow_back,
                      size: 24, color: KazaTheme.azulKaza),
                ),
              ),
              const Text('Publicar propiedad',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: KazaTheme.azulKaza)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isPublishing ? null : _goNext,
              child: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(_currentPage == 10 ? 'Publicar ahora' : 'Continuar',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/map'),
            child: const Text('Guardar borrador',
                style: TextStyle(
                    color: KazaTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
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
      _selectionCard(
          'Publicar nueva propiedad',
          'Crear un nuevo anuncio desde cero',
          Icons.add,
          true,
          () => _goNext()),
      const SizedBox(height: 16),
      _selectionCard('Republicar', 'Usar una publicación anterior',
          Icons.refresh, false, () {}),
    ]);
  }

  Widget _buildStep02Operacion() {
    final ops = ['Venta', 'Alquiler', 'Alquiler temporal', 'Anticrético'];
    return _stepContainer(
        '02',
        'Tipo de operación',
        'Define el tipo de operación.',
        ops.map((op) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _selectionCard(op, 'Publica para ${op.toLowerCase()}',
                Icons.sell_outlined, _operationType == op, () {
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
    return _stepContainer(
        '03', 'Tipo de propiedad', 'Selecciona el tipo de propiedad.', [
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
                border: Border.all(
                    color: isSel ? KazaTheme.azulKaza : KazaTheme.glassBorder,
                    width: isSel ? 2 : 1),
                borderRadius: BorderRadius.circular(12),
                color: isSel
                    ? KazaTheme.azulKaza.withValues(alpha: 0.05)
                    : Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t['icon'] as IconData,
                      color:
                          isSel ? KazaTheme.azulKaza : KazaTheme.textSecondary,
                      size: 32),
                  const SizedBox(height: 8),
                  Text(t['label'] as String,
                      style: TextStyle(
                          color: isSel
                              ? KazaTheme.azulKaza
                              : KazaTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
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
        decoration: BoxDecoration(
            color: KazaTheme.grisClaro,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.search, color: KazaTheme.grisMedio),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                    hintText: 'Buscar dirección o lugar',
                    border: InputBorder.none,
                    isDense: true),
                style: const TextStyle(fontSize: 14),
                onSubmitted: _searchLocation,
              ),
            ),
            if (_isSearchingLocation)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: KazaTheme.grisClaro,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            mapController: _mapController,
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
              TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kaza.app'),
              MarkerLayer(markers: [
                Marker(
                  point: LatLng(_selectedLat, _selectedLng),
                  width: 44,
                  height: 56,
                  child: CustomPaint(
                      painter: KazaPinPainter(
                          icon: Icons.location_on, isSelected: true)),
                ),
              ]),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildStep05Caracteristicas() {
    return _stepContainer(
        '05', 'Características', 'Agrega los detalles principales.', [
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
            items: ['USD', 'BOB']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _currency = v!),
            underline: const SizedBox(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.azulKaza),
              decoration: const InputDecoration(
                  hintText: 'Ej. 125000', border: UnderlineInputBorder()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      SwitchListTile(
        title: const Text('Precio negociable',
            style: TextStyle(fontWeight: FontWeight.w600)),
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
    return _stepContainer(
        '08', 'Descripción', 'Cuenta lo mejor de tu propiedad.', [
      TextField(
        controller: _titleCtrl,
        maxLength: 60,
        decoration: const InputDecoration(
            labelText: 'Título de la publicación',
            hintText: 'Ej. Moderno departamento...'),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _descCtrl,
        maxLines: 6,
        maxLength: 1000,
        decoration: const InputDecoration(
            labelText: 'Descripción detallada',
            hintText: 'Describe los ambientes, acabados, entorno...',
            alignLabelWithHint: true),
      ),
    ]);
  }

  Widget _buildStep09Amenities() {
    return _stepContainer('09', 'Amenities', 'Selecciona las amenidades.', [
      const Text('Populares', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
    return _stepContainer(
        '10', 'Anunciante', 'Quién publica y cómo contactarlo.', [
      TextField(
          controller: _contactNameCtrl,
          decoration: const InputDecoration(
              labelText: 'Nombre de contacto',
              prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 16),
      TextField(
          controller: _contactPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
              labelText: 'WhatsApp', prefixIcon: Icon(Icons.phone_outlined))),
      const SizedBox(height: 24),
      SwitchListTile(
        title: const Text('Mostrar contacto',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Los interesados verán tu contacto'),
        value: _showContact,
        onChanged: (v) => setState(() => _showContact = v),
        activeColor: KazaTheme.primaryCoral,
        contentPadding: EdgeInsets.zero,
      ),
    ]);
  }

  Widget _buildStep11Revision() {
    return _stepContainer(
        '11', 'Revisión', 'Revisa y confirma tu publicación.', [
      _reviewRow('Operación', _operationType),
      _reviewRow('Propiedad', _propertyType),
      _reviewRow('Precio', '$_currency ${_priceCtrl.text}'),
      _reviewRow(
          'Ubicación',
          _addressCtrl.text.isNotEmpty
              ? _addressCtrl.text
              : 'Lat: $_selectedLat, Lng: $_selectedLng'),
      _reviewRow('Superficie', '${_terrainCtrl.text} m²'),
      _reviewRow('Dorm/Baños',
          '${_bedroomsCtrl.text} dorm - ${_bathroomsCtrl.text} baños'),
      _reviewRow('Fotos', '${_mediaItems.length} agregadas'),
      _reviewRow(
          'Contacto', '${_contactNameCtrl.text} (${_contactPhoneCtrl.text})'),
    ]);
  }

  Widget _buildStep12Exito() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle,
                size: 80, color: KazaTheme.semanticSuccess),
            const SizedBox(height: 24),
            const Text('¡Publicación enviada!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: KazaTheme.azulKaza)),
            const SizedBox(height: 12),
            const Text(
                'Tu propiedad está en revisión.\nTe notificaremos cuando esté activa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: KazaTheme.textSecondary)),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: KazaTheme.azulKaza,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => context.go('/profile'),
                child: const Text('Ver mis publicaciones',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/map'),
              child: const Text('Volver al mapa',
                  style: TextStyle(
                      color: KazaTheme.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMMONS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _stepContainer(
      String number, String title, String subtitle, List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(number,
                  style: const TextStyle(
                      color: KazaTheme.primaryCoral,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: KazaTheme.azulKaza,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: KazaTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _selectionCard(String title, String subtitle, IconData icon,
      bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? KazaTheme.azulKaza : KazaTheme.glassBorder,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? KazaTheme.azulKaza.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? KazaTheme.azulKaza : KazaTheme.grisMedio,
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected
                              ? KazaTheme.azulKaza
                              : KazaTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: KazaTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: KazaTheme.azulKaza),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KazaTheme.textPrimary)),
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
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
              IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
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
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      color: KazaTheme.textSecondary, fontSize: 14))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: KazaTheme.azulKaza,
                      fontSize: 14,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
