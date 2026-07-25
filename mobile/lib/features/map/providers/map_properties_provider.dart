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

/// Provider de Riverpod para consultar propiedades desde Supabase PostgreSQL + PostGIS
final mapPropertiesProvider = FutureProvider<List<PropertyMapItem>>((ref) async {
  try {
    final response = await SupabaseConfig.client
        .from('properties')
        .select('*');

    final List<PropertyMapItem> items = [];
    for (final row in response) {
      final double lat = (row['latitude'] as num?)?.toDouble() ?? -17.7833;
      final double lng = (row['longitude'] as num?)?.toDouble() ?? -63.1821;
      final num price = (row['price_usd'] as num?) ?? 0;

      items.add(PropertyMapItem(
        id: row['id'].toString(),
        title: row['address_canonical'] ?? 'Propiedad Kaza',
        price: price > 0 ? '\$ ${price.toStringAsFixed(0)}' : 'Consultar',
        operation: row['operation'] ?? 'VENTA',
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

    return items;
  } catch (e) {
    return [];
  }
});
