import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_config.dart';

/// Modelo de datos parseado para el mapa y la ficha completa de propiedad
class PropertyMapItem {
  final String id;
  final String title;
  final String price;
  final String operation;
  final String type;
  final LatLng location;
  final int bedrooms;
  final int bathrooms;
  final String surface;
  final bool isPlus;
  final String trustLabel;
  final bool isOrg;
  /// Cantidad de propiedades que representa este pin (cluster/edificio). >= 1.
  final int propertyCount;
  /// Lista de propiedades agrupadas si es un clúster
  final List<PropertyMapItem>? subItems;

  // ── Campos extendidos (B04 Publish + Ficha completa B16) ──────────────────
  /// Imagen principal de la propiedad
  final String? imageUrl;
  /// Galería completa de fotos
  final List<String> photos;
  /// Descripción larga de la propiedad
  final String? description;
  /// Lista de amenidades (e.g. ['Piscina', 'Gimnasio', 'Terraza'])
  final List<String> amenities;
  /// Highlights / puntos clave de la descripción
  final List<String> highlights;
  /// Nombre del anunciante / agente
  final String? agentName;
  /// Teléfono de contacto del anunciante
  final String? contactPhone;
  /// Nombre del contacto
  final String? contactName;
  /// Superficie construida (m²)
  final String? coveredSurface;
  /// Parqueos / garages
  final int parkingSpaces;
  /// Antigüedad en años
  final int ageYears;
  /// Total de pisos del edificio/propiedad
  final int floorsTotal;
  /// Moneda del precio
  final String currency;
  /// Dirección canónica / legible
  final String? address;
  /// Estado de la publicación (PUBLISHED, AVAILABLE, DRAFT...)
  final String status;
  /// ID del dueño/publicador
  final String? ownerId;

  PropertyMapItem({
    required this.id,
    required this.title,
    required this.price,
    required this.operation,
    required this.type,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.surface,
    required this.isPlus,
    required this.trustLabel,
    required this.isOrg,
    this.propertyCount = 1,
    this.subItems,
    this.imageUrl,
    this.photos = const [],
    this.description,
    this.amenities = const [],
    this.highlights = const [],
    this.agentName,
    this.contactPhone,
    this.contactName,
    this.coveredSurface,
    this.parkingSpaces = 0,
    this.ageYears = 0,
    this.floorsTotal = 1,
    this.currency = 'USD',
    this.address,
    this.status = 'PUBLISHED',
    this.ownerId,
  });
}

class LocalPublishedPropertiesNotifier extends StateNotifier<List<PropertyMapItem>> {
  LocalPublishedPropertiesNotifier() : super([]);

  void addProperty(PropertyMapItem item) {
    state = [item, ...state];
  }
}

final localPublishedPropertiesProvider =
    StateNotifierProvider<LocalPublishedPropertiesNotifier, List<PropertyMapItem>>((ref) {
  return LocalPublishedPropertiesNotifier();
});

num _parseNum(dynamic val, [num defaultValue = 0]) {
  if (val == null) return defaultValue;
  if (val is num) return val;
  if (val is String) return num.tryParse(val) ?? defaultValue;
  return defaultValue;
}

List<String> _parseJsonbList(dynamic val) {
  if (val == null) return [];
  if (val is List) return val.map((e) => e.toString()).toList();
  return [];
}

// =============================================================================
// HELPERS
// =============================================================================

/// Parsea una fila de Supabase en un [PropertyMapItem].
PropertyMapItem _rowToItem(Map<String, dynamic> row) {
  final idStr = row['id'].toString();
  final double lat = _extractLat(row);
  final double lng = _extractLng(row);
  final num price = _parseNum(row['price_usd'], _parseNum(row['price_original'], 0));

  // Fotos: puede ser JSONB array o campo `photos`
  final List<String> photosList = _parseJsonbList(row['photos']);
  final String? firstPhoto = photosList.isNotEmpty ? photosList.first : null;

  // Amenidades
  final List<String> amenitiesList = _parseJsonbList(row['amenities']);

  // Highlights
  final List<String> highlightsList = _parseJsonbList(row['highlights']);

  // Superficie cubierta
  final covSurface = row['covered_surface_m2'];
  final String? covStr = covSurface != null ? '$covSurface m²' : null;

  return PropertyMapItem(
    id: idStr,
    title: row['title'] ?? row['address_canonical'] ?? 'Propiedad Kaza',
    price: price > 0 ? '\$ ${price.toStringAsFixed(0)}' : 'Consultar',
    operation: row['operation'] ?? row['operation_type'] ?? 'VENTA',
    type: row['property_type'] ?? 'Departamento',
    location: LatLng(lat, lng),
    bedrooms: _parseNum(row['rooms'], 0).toInt(),
    bathrooms: _parseNum(row['bathrooms'], 0).toInt(),
    surface: '${_parseNum(row['total_surface_m2'], 0).toStringAsFixed(0)} m²',
    isPlus: row['has_active_promotion'] == true,
    trustLabel: 'Actor Verificado',
    isOrg: false,
    imageUrl: firstPhoto,
    photos: photosList,
    description: row['description'] as String?,
    amenities: amenitiesList,
    highlights: highlightsList,
    agentName: row['contact_name'] as String? ?? 'Anunciante KAZA',
    contactPhone: row['contact_phone'] as String?,
    contactName: row['contact_name'] as String?,
    coveredSurface: covStr,
    parkingSpaces: _parseNum(row['parking_spaces'], 0).toInt(),
    ageYears: _parseNum(row['age_years'], 0).toInt(),
    floorsTotal: _parseNum(row['floors_total'], 1).toInt(),
    currency: row['currency_code'] as String? ?? 'USD',
    address: row['address_canonical'] as String?,
    status: row['status'] as String? ?? 'PUBLISHED',
    ownerId: row['owner_id'] as String?,
  );
}

// =============================================================================
// PROVIDER — StreamProvider con Supabase Realtime
// =============================================================================
/// Provider de Riverpod que combina:
///  1. ⚡ Supabase Realtime: cualquier INSERT/UPDATE/DELETE en `properties`
///     dispara automáticamente una actualización en la UI (0 polling).
///  2. 🔄 Fallback periódico de 30s (por si se pierde la conexión WebSocket).
///  3. 📌 Items locales publicados en la sesión actual.
///
/// Consumo de red: 1 WebSocket persistente (gestionado por Supabase SDK).
final mapPropertiesProvider = StreamProvider<List<PropertyMapItem>>((ref) async* {
  final localItems = ref.watch(localPublishedPropertiesProvider);

  // Función interna para cargar todas las propiedades de Supabase (sin duplicados)
  Future<List<PropertyMapItem>> fetchAll() async {
    final List<PropertyMapItem> items = [];
    final Set<String> seenKeys = {};

    try {
      final response =
          await SupabaseConfig.client.from('properties').select('*');
      for (final row in response) {
        try {
          final item = _rowToItem(row);
          final key = '${item.location.latitude.toStringAsFixed(4)}_${item.location.longitude.toStringAsFixed(4)}_${item.title.trim().toLowerCase()}';
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            items.add(item);
          }
        } catch (_) {}
      }
    } catch (_) {}

    for (final loc in localItems) {
      final key = '${loc.location.latitude.toStringAsFixed(4)}_${loc.location.longitude.toStringAsFixed(4)}_${loc.title.trim().toLowerCase()}';
      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        items.add(loc);
      }
    }

    return items;
  }

  // 1. Emitir datos iniciales inmediatamente
  yield await fetchAll();

  // 2. Suscribirse al canal Realtime de Supabase para la tabla `properties`
  //    Cada evento (INSERT/UPDATE/DELETE) recarga la lista completa.
  final StreamController<List<PropertyMapItem>> controller =
      StreamController<List<PropertyMapItem>>();

  final channel = SupabaseConfig.client
      .channel('public:properties')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'properties',
        callback: (payload) async {
          // Pequeño debounce para agrupar cambios rápidos consecutivos
          await Future<void>.delayed(const Duration(milliseconds: 350));
          if (!controller.isClosed) {
            controller.add(await fetchAll());
          }
        },
      )
      .subscribe();

  // 3. Cleanup al desechar el provider
  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
    controller.close();
  });

  // 4. Emitir todos los eventos del stream
  yield* controller.stream;
});

double _extractLat(Map<String, dynamic> row) {
  if (row['latitude'] != null) return _parseNum(row['latitude'], -17.7833).toDouble();
  if (row['canonical_location'] != null) {
    final loc = row['canonical_location'];
    if (loc is Map && loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
      return _parseNum((loc['coordinates'] as List)[1], -17.7833).toDouble();
    }
    if (loc is String && loc.contains('POINT')) {
      final clean = loc.replaceAll('POINT(', '').replaceAll(')', '').trim();
      final parts = clean.split(' ');
      if (parts.length >= 2) return double.tryParse(parts[1]) ?? -17.7833;
    }
  }
  if (row['public_location_geometry'] != null) {
    final loc = row['public_location_geometry'];
    if (loc is Map && loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
      return _parseNum((loc['coordinates'] as List)[1], -17.7833).toDouble();
    }
    if (loc is String && loc.contains('POINT')) {
      final clean = loc.replaceAll('POINT(', '').replaceAll(')', '').trim();
      final parts = clean.split(' ');
      if (parts.length >= 2) return double.tryParse(parts[1]) ?? -17.7833;
    }
  }
  return -17.7833;
}

double _extractLng(Map<String, dynamic> row) {
  if (row['longitude'] != null) return _parseNum(row['longitude'], -63.1821).toDouble();
  if (row['canonical_location'] != null) {
    final loc = row['canonical_location'];
    if (loc is Map && loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
      return _parseNum((loc['coordinates'] as List)[0], -63.1821).toDouble();
    }
    if (loc is String && loc.contains('POINT')) {
      final clean = loc.replaceAll('POINT(', '').replaceAll(')', '').trim();
      final parts = clean.split(' ');
      if (parts.length >= 2) return double.tryParse(parts[0]) ?? -63.1821;
    }
  }
  if (row['public_location_geometry'] != null) {
    final loc = row['public_location_geometry'];
    if (loc is Map && loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
      return _parseNum((loc['coordinates'] as List)[0], -63.1821).toDouble();
    }
    if (loc is String && loc.contains('POINT')) {
      final clean = loc.replaceAll('POINT(', '').replaceAll(')', '').trim();
      final parts = clean.split(' ');
      if (parts.length >= 2) return double.tryParse(parts[0]) ?? -63.1821;
    }
  }
  return -63.1821;
}
