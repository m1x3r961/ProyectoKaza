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
  // Si Supabase no está inicializado con la clave anon, retornar datos demo
  if (SupabaseConfig.supabaseAnonKey == 'TU_SUPABASE_ANON_KEY_AQUI') {
    return _getDemoProperties();
  }

  try {
    final response = await SupabaseConfig.client
        .from('properties')
        .select('id, property_type, total_surface_m2, rooms, bathrooms, address_canonical');

    final List<PropertyMapItem> items = [];
    for (final row in response) {
      items.add(PropertyMapItem(
        id: row['id'] as String,
        title: row['address_canonical'] ?? 'Propiedad Kaza',
        price: '\$ 120,000',
        operation: 'VENTA',
        type: row['property_type'] ?? 'Departamento',
        location: const LatLng(-17.7833, -63.1821),
        bedrooms: (row['rooms'] as num?)?.toInt() ?? 2,
        bathrooms: (row['bathrooms'] as num?)?.toInt() ?? 2,
        surface: '${row['total_surface_m2'] ?? 80} m²',
        isPlus: true,
        trustLabel: 'Actor Verificado',
        isOrg: true,
      ));
    }

    return items.isEmpty ? _getDemoProperties() : items;
  } catch (e) {
    return _getDemoProperties();
  }
});

List<PropertyMapItem> _getDemoProperties() {
  return [
    PropertyMapItem(
      id: 'prop-1',
      title: 'Departamento Ejecutivo Equipetrol',
      price: '\$ 128,000',
      operation: 'VENTA',
      type: 'Departamento',
      location: const LatLng(-17.7780, -63.1810),
      bedrooms: 2,
      bathrooms: 2,
      surface: '85 m²',
      isPlus: true,
      trustLabel: 'Inmobiliaria Verificada',
      isOrg: true,
    ),
    PropertyMapItem(
      id: 'prop-2',
      title: 'Casa Moderna en Urubó West',
      price: '\$ 340,000',
      operation: 'VENTA',
      type: 'Casa',
      location: const LatLng(-17.7650, -63.2050),
      bedrooms: 4,
      bathrooms: 4,
      surface: '320 m²',
      isPlus: true,
      trustLabel: 'Propietario Legítimo',
      isOrg: false,
    ),
    PropertyMapItem(
      id: 'prop-3',
      title: 'Oficina Comercial Sirari',
      price: '\$ 950 / mes',
      operation: 'ALQUILER',
      type: 'Oficina',
      location: const LatLng(-17.7890, -63.1780),
      bedrooms: 1,
      bathrooms: 1,
      surface: '50 m²',
      isPlus: false,
      trustLabel: 'Agente Certificado',
      isOrg: true,
    ),
  ];
}
