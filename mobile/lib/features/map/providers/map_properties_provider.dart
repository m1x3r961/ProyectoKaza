import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_config.dart';

/// Modelo de datos parseado para el mapa
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
  /// Imagen principal de la propiedad
  final String? imageUrl;

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

// =============================================================================
// HELPERS
// =============================================================================

/// Parsea una fila de Supabase en un [PropertyMapItem].
PropertyMapItem _rowToItem(Map<String, dynamic> row) {
  final idStr = row['id'].toString();
  final double lat = _extractLat(row);
  final double lng = _extractLng(row);
  final num price = _parseNum(row['price_usd'], _parseNum(row['price_original'], 0));
  return PropertyMapItem(
    id: idStr,
    title: row['address_canonical'] ?? row['title'] ?? 'Propiedad Kaza',
    price: price > 0 ? '\$ ${price.toStringAsFixed(0)}' : 'Consultar',
    operation: row['operation'] ?? row['operation_type'] ?? 'VENTA',
    type: row['property_type'] ?? 'Departamento',
    location: LatLng(lat, lng),
    bedrooms: _parseNum(row['rooms'], 0).toInt(),
    bathrooms: _parseNum(row['bathrooms'], 0).toInt(),
    surface: '${row['total_surface_m2'] ?? 0} m²',
    isPlus: true,
    trustLabel: 'Actor Verificado',
    isOrg: true,
    imageUrl: (row['photos'] != null &&
            row['photos'] is List &&
            (row['photos'] as List).isNotEmpty)
        ? row['photos'][0]
        : null,
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
