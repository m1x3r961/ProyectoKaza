import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/widgets/kaza_pin_painter.dart';

/// 🟢 POI LAYER — "10 CAPAS POI"
/// Points of interest layer with distinct visual grammar (green dots, not pins)

/// POI data model
class PoiItem {
  final String id;
  final String name;
  final PoiCategory category;
  final LatLng location;

  const PoiItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
  });
}

enum PoiCategory {
  education,
  health,
  commerce,
  transport,
}

extension PoiCategoryExt on PoiCategory {
  String get label {
    switch (this) {
      case PoiCategory.education: return 'Educación';
      case PoiCategory.health: return 'Salud';
      case PoiCategory.commerce: return 'Comercios';
      case PoiCategory.transport: return 'Transporte';
    }
  }

  IconData get icon {
    switch (this) {
      case PoiCategory.education: return Icons.school_rounded;
      case PoiCategory.health: return Icons.local_hospital_rounded;
      case PoiCategory.commerce: return Icons.storefront_rounded;
      case PoiCategory.transport: return Icons.directions_bus_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PoiCategory.education: return const Color(0xFF9C27B0);
      case PoiCategory.health: return const Color(0xFFE53935);
      case PoiCategory.commerce: return const Color(0xFFF5A623);
      case PoiCategory.transport: return const Color(0xFF1E88E5);
    }
  }
}

/// Builds POI markers for the map
class PoiLayerBuilder {
  /// Generate marker widgets for POI items
  static List<Marker> buildMarkers({
    required List<PoiItem> pois,
    bool showEducation = true,
    bool showHealth = true,
    bool showCommerce = true,
    bool showTransport = true,
  }) {
    return pois.where((poi) {
      switch (poi.category) {
        case PoiCategory.education: return showEducation;
        case PoiCategory.health: return showHealth;
        case PoiCategory.commerce: return showCommerce;
        case PoiCategory.transport: return showTransport;
      }
    }).map((poi) {
      return Marker(
        point: poi.location,
        width: 28,
        height: 28,
        child: Tooltip(
          message: poi.name,
          child: CustomPaint(
            painter: KazaPoiPinPainter(
              color: poi.category.color,
              icon: poi.category.icon,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Generate sample/mock POI data for a given center point
  static List<PoiItem> generateMockPois(LatLng center) {
    return [
      // Education
      PoiItem(id: 'edu1', name: 'Colegio San Agustín', category: PoiCategory.education,
          location: LatLng(center.latitude + 0.005, center.longitude + 0.003)),
      PoiItem(id: 'edu2', name: 'Universidad Mayor', category: PoiCategory.education,
          location: LatLng(center.latitude - 0.004, center.longitude + 0.007)),
      PoiItem(id: 'edu3', name: 'Instituto Tecnológico', category: PoiCategory.education,
          location: LatLng(center.latitude + 0.008, center.longitude - 0.002)),

      // Health
      PoiItem(id: 'hea1', name: 'Hospital Municipal', category: PoiCategory.health,
          location: LatLng(center.latitude + 0.003, center.longitude - 0.005)),
      PoiItem(id: 'hea2', name: 'Clínica del Sol', category: PoiCategory.health,
          location: LatLng(center.latitude - 0.006, center.longitude - 0.003)),

      // Commerce
      PoiItem(id: 'com1', name: 'Centro Comercial Las Brisas', category: PoiCategory.commerce,
          location: LatLng(center.latitude - 0.002, center.longitude + 0.005)),
      PoiItem(id: 'com2', name: 'Mercado Central', category: PoiCategory.commerce,
          location: LatLng(center.latitude + 0.006, center.longitude + 0.006)),
      PoiItem(id: 'com3', name: 'Supermercado Nacional', category: PoiCategory.commerce,
          location: LatLng(center.latitude - 0.007, center.longitude + 0.001)),

      // Transport
      PoiItem(id: 'tra1', name: 'Terminal Bimodal', category: PoiCategory.transport,
          location: LatLng(center.latitude + 0.001, center.longitude - 0.007)),
      PoiItem(id: 'tra2', name: 'Parada Línea 15', category: PoiCategory.transport,
          location: LatLng(center.latitude - 0.003, center.longitude - 0.006)),
    ];
  }
}
