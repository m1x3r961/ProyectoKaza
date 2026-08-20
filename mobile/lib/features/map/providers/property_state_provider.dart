import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/supabase_config.dart';
import '../providers/map_properties_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEV11-E · PROPERTY STATE PROVIDER
// Lee la propiedad FRESCA desde Supabase y determina el KazaUIState
// correcto basado en los campos reales del backend.
//
// Principios aplicados:
//   ✅ Estados explícitos y predecibles
//   ✅ Nunca ocultar errores al usuario
//   ✅ Siempre orientado a la acción
// ─────────────────────────────────────────────────────────────────────────────

/// Enum con los 12 estados representativos DEV11-E del sistema KAZA.
enum KazaUIState {
  loading,              // 01 · Cargando
  empty,                // 02 · Sin resultados
  error,                // 03 · Error inesperado
  restricted,           // 04 · Contenido restringido
  permissionRequired,   // 05 · Permiso requerido
  entitlementRequired,  // 06 · Plan requerido
  offline,              // 07 · Sin conexión
  partialData,          // 08 · Datos incompletos
  unknown,              // 09 · Desconocido
  confirmationRequired, // 10 · Confirmación requerida
  backendSuccess,       // 11 · Disponible y completo
  deepLinkReauthorization, // 12 · Revalidación de enlace
}

/// Resultado: propiedad + estado DEV11-E + mensaje contextual.
class PropertyWithState {
  final PropertyMapItem? property;
  final KazaUIState uiState;
  final String? stateMessage;

  const PropertyWithState({
    this.property,
    required this.uiState,
    this.stateMessage,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// FutureProvider.family<PropertyWithState, String>(propertyId)
// Carga fresco desde Supabase y mapea al estado DEV11-E correcto.
// ─────────────────────────────────────────────────────────────────────────────
final propertyStateProvider =
    FutureProvider.family<PropertyWithState, String>((ref, propertyId) async {
  try {
    final response = await SupabaseConfig.client
        .from('properties')
        .select('*')
        .eq('id', propertyId)
        .maybeSingle();

    // ── 02 · Empty — propiedad no encontrada ──────────────────────────────
    if (response == null) {
      return const PropertyWithState(
        uiState: KazaUIState.empty,
        stateMessage: 'Esta propiedad ya no está disponible en KAZA.',
      );
    }

    final row = response;
    final status = (row['status'] as String? ?? 'PUBLISHED').toUpperCase();

    // ── 04 · Restricted — bloqueada o suspendida ──────────────────────────
    if (status == 'BLOCKED' || status == 'SUSPENDED') {
      return const PropertyWithState(
        uiState: KazaUIState.restricted,
        stateMessage: 'Este contenido no está disponible en tu zona o región.',
      );
    }

    // ── 06 · Entitlement — solo para plan premium ─────────────────────────
    if (status == 'PREMIUM_ONLY') {
      return const PropertyWithState(
        uiState: KazaUIState.entitlementRequired,
        stateMessage: 'Esta propiedad es exclusiva para usuarios Plus, Pro o Business.',
      );
    }

    // ── Parsear el item completo ───────────────────────────────────────────
    final item = _parseRow(row);

    // ── 09 · Unknown — sin datos geoespaciales ni título ──────────────────
    if (row['latitude'] == null && row['longitude'] == null &&
        (item.title.isEmpty || item.title == 'Propiedad KAZA')) {
      return const PropertyWithState(
        uiState: KazaUIState.unknown,
        stateMessage: 'Aún no tenemos datos completos para esta propiedad.',
      );
    }

    // ── 08 · Partial Data — datos incompletos o desactualizados ──────────
    final updatedAt = row['updated_at'] as String?;
    final staleResult = _checkStaleness(updatedAt);
    final hasPhotos = item.photos.isNotEmpty;
    final hasDesc   = item.description != null && item.description!.isNotEmpty;

    if (staleResult != null || !hasPhotos || !hasDesc) {
      return PropertyWithState(
        property: item,
        uiState: KazaUIState.partialData,
        stateMessage: staleResult ??
            'Información parcial — algunos datos están incompletos.',
      );
    }

    // ── 11 · Backend Success — propiedad completa y disponible ────────────
    return PropertyWithState(
      property: item,
      uiState: KazaUIState.backendSuccess,
    );
  } on Exception catch (e) {
    final msg = e.toString().toLowerCase();

    // ── 07 · Offline ──────────────────────────────────────────────────────
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('internet') ||
        msg.contains('failed host lookup')) {
      return const PropertyWithState(
        uiState: KazaUIState.offline,
        stateMessage: 'Sin conexión — Verifica tu internet e intenta nuevamente.',
      );
    }

    // ── 03 · Error ────────────────────────────────────────────────────────
    return PropertyWithState(
      uiState: KazaUIState.error,
      stateMessage: 'No pudimos cargar la propiedad. Inténtalo nuevamente.',
    );
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Retorna mensaje de obsolescencia si los datos tienen más de 30 días.
String? _checkStaleness(String? updatedAt) {
  if (updatedAt == null) return null;
  final updated = DateTime.tryParse(updatedAt);
  if (updated == null) return null;
  final diff = DateTime.now().difference(updated);
  if (diff.inDays > 30) {
    return 'Actualizado hace ${diff.inDays} días — Algunos datos pueden variar.';
  }
  return null;
}

num _n(dynamic v, [num d = 0]) {
  if (v == null) return d;
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? d;
  return d;
}

List<String> _lst(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

double _lat(Map<String, dynamic> r) =>
    _n(r['latitude'], -17.7833).toDouble();

double _lng(Map<String, dynamic> r) =>
    _n(r['longitude'], -63.1821).toDouble();

/// Parsea una fila de Supabase en un [PropertyMapItem].
PropertyMapItem _parseRow(Map<String, dynamic> row) {
  final photos  = _lst(row['photos']);
  final num px  = _n(row['price_usd'], _n(row['price_original'], 0));
  final cov     = row['covered_surface_m2'];

  return PropertyMapItem(
    id:             row['id'].toString(),
    title:          row['title'] as String? ??
                    row['address_canonical'] as String? ??
                    'Propiedad KAZA',
    price:          px > 0 ? '\$ ${px.toStringAsFixed(0)}' : 'Consultar',
    operation:      row['operation'] as String? ??
                    row['operation_type'] as String? ?? 'VENTA',
    type:           row['property_type'] as String? ?? 'Departamento',
    location:       LatLng(_lat(row), _lng(row)),
    bedrooms:       _n(row['rooms'], 0).toInt(),
    bathrooms:      _n(row['bathrooms'], 0).toInt(),
    surface:        '${_n(row['total_surface_m2'], 0).toStringAsFixed(0)} m²',
    isPlus:         row['has_active_promotion'] == true,
    trustLabel:     'Actor Verificado',
    isOrg:          false,
    imageUrl:       photos.isNotEmpty ? photos.first : null,
    photos:         photos,
    description:    row['description'] as String?,
    amenities:      _lst(row['amenities']),
    highlights:     _lst(row['highlights']),
    agentName:      row['contact_name'] as String? ?? 'Anunciante KAZA',
    contactPhone:   row['contact_phone'] as String?,
    contactName:    row['contact_name'] as String?,
    coveredSurface: cov != null ? '$cov m²' : null,
    parkingSpaces:  _n(row['parking_spaces'], 0).toInt(),
    ageYears:       _n(row['age_years'], 0).toInt(),
    floorsTotal:    _n(row['floors_total'], 1).toInt(),
    currency:       row['currency_code'] as String? ?? 'USD',
    address:        row['address_canonical'] as String?,
    status:         row['status'] as String? ?? 'PUBLISHED',
    ownerId:        row['owner_id'] as String?,
  );
}
