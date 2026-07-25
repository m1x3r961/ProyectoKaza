import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
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

/// Provider de Riverpod para consultar propiedades desde Supabase PostgreSQL + PostGIS + Local Session
final mapPropertiesProvider = FutureProvider<List<PropertyMapItem>>((ref) async {
  final localItems = ref.watch(localPublishedPropertiesProvider);
  final List<PropertyMapItem> items = [...localItems];

  try {
    final response = await SupabaseConfig.client
        .from('properties')
        .select('*');

    for (final row in response) {
      final idStr = row['id'].toString();
      // Evitar duplicados si ya está en localItems
      if (items.any((it) => it.id == idStr)) continue;

      final double lat = _extractLat(row);
      final double lng = _extractLng(row);
      final num price = (row['price_usd'] as num?) ?? (row['price_original'] as num?) ?? 0;

      items.add(PropertyMapItem(
        id: idStr,
        title: row['address_canonical'] ?? row['title'] ?? 'Propiedad Kaza',
        price: price > 0 ? '\$ ${price.toStringAsFixed(0)}' : 'Consultar',
        operation: row['operation'] ?? row['operation_type'] ?? 'VENTA',
        type: row['property_type'] ?? 'Departamento',
        location: LatLng(lat, lng),
        bedrooms: (row['rooms'] as num?)?.toInt() ?? 0,
        bathrooms: (row['bathrooms'] as num?)?.toInt() ?? 0,
        surface: '${row['total_surface_m2'] ?? 0} m²',
        isPlus: true,
        trustLabel: 'Actor Verificado',
        isOrg: true,
      ));
    }
  } catch (_) {}

  return items;
});

double _extractLat(Map<String, dynamic> row) {
  if (row['latitude'] != null) return (row['latitude'] as num).toDouble();
  if (row['canonical_location'] != null) {
    final loc = row['canonical_location'];
    if (loc is Map && loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
      return ((loc['coordinates'] as List)[1] as num).toDouble();
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
      return ((loc['coordinates'] as List)[1] as num).toDouble();
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
  if (row['longitude'] != null) return (row['longitude'] as num).toDouble();
  if (row['canonical_location'] != null) {
    final loc = row['canonical_location'];
    if (loc is Map && loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
      return ((loc['coordinates'] as List)[0] as num).toDouble();
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
      return ((loc['coordinates'] as List)[0] as num).toDouble();
    }
    if (loc is String && loc.contains('POINT')) {
      final clean = loc.replaceAll('POINT(', '').replaceAll(')', '').trim();
      final parts = clean.split(' ');
      if (parts.length >= 2) return double.tryParse(parts[0]) ?? -63.1821;
    }
  }
  return -63.1821;
}
