import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_representative_states.dart';
import '../providers/property_state_provider.dart';
import '../providers/map_properties_provider.dart';
import 'property_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEV11-E · PROPERTY STATE WRAPPER
// Envuelve la ficha completa (PropertyDetailScreen) con el estado
// representativo correcto basado en los datos reales del backend.
//
// Flujo:
//   loading      → KazaLoadingState (spinner coral)
//   empty        → KazaEmptyState
//   error        → KazaErrorState (con retry)
//   restricted   → KazaRestrictedState
//   entitlement  → KazaEntitlementRequiredState
//   offline      → KazaOfflineState (con retry)
//   partialData  → PropertyDetailScreen con banner de advertencia
//   unknown      → KazaUnknownState
//   success      → PropertyDetailScreen completo
// ─────────────────────────────────────────────────────────────────────────────

class PropertyStateWrapper extends ConsumerWidget {
  /// ID de la propiedad a cargar desde Supabase.
  final String propertyId;

  /// Propiedad pre-cargada (del pin del mapa). Úsala como fallback
  /// mientras se cargan los datos frescos del backend.
  final PropertyMapItem? preloadedProperty;

  const PropertyStateWrapper({
    super.key,
    required this.propertyId,
    this.preloadedProperty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(propertyStateProvider(propertyId));

    return stateAsync.when(
      // ── 01 · Loading ───────────────────────────────────────────────────────
      loading: () {
        // Si ya tenemos datos pre-cargados del mapa, mostrar la ficha
        // directamente mientras se refresca en background.
        if (preloadedProperty != null) {
          return PropertyDetailScreen(property: preloadedProperty!);
        }
        return const Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: KazaLoadingState(message: 'Cargando ficha de propiedad…'),
          ),
        );
      },

      // ── Error handler (convierte al estado DEV11-E correcto) ──────────────
      error: (err, _) => _buildFromState(
        context,
        ref,
        PropertyWithState(
          property: preloadedProperty,
          uiState: KazaUIState.error,
          stateMessage: 'No pudimos cargar la propiedad. Inténtalo nuevamente.',
        ),
      ),

      // ── Data: determina el estado y renderiza ─────────────────────────────
      data: (result) => _buildFromState(context, ref, result),
    );
  }

  Widget _buildFromState(
    BuildContext context,
    WidgetRef ref,
    PropertyWithState result,
  ) {
    switch (result.uiState) {
      // ── 11 · Backend Success — ficha completa ─────────────────────────────
      case KazaUIState.backendSuccess:
        return PropertyDetailScreen(property: result.property!);

      // ── 08 · Partial Data — ficha con banner de advertencia ───────────────
      case KazaUIState.partialData:
        final property = result.property ?? preloadedProperty;
        if (property == null) {
          return _scaffold(const KazaUnknownState());
        }
        return _withPartialBanner(context, ref, property, result.stateMessage);

      // ── 02 · Empty ────────────────────────────────────────────────────────
      case KazaUIState.empty:
        return _scaffold(KazaEmptyState(
          title: 'Propiedad no disponible',
          subtitle: result.stateMessage ?? 'Esta propiedad ya no está disponible.',
          onAdjustFilters: () => Navigator.pop(context),
        ));

      // ── 03 · Error ────────────────────────────────────────────────────────
      case KazaUIState.error:
        return _scaffold(KazaErrorState(
          subtitle: result.stateMessage ?? 'No pudimos cargar la propiedad.',
          onRetry: () => ref.invalidate(propertyStateProvider(propertyId)),
        ));

      // ── 04 · Restricted ───────────────────────────────────────────────────
      case KazaUIState.restricted:
        return _scaffold(KazaRestrictedState(
          onExploreOtherZones: () => Navigator.pop(context),
        ));

      // ── 06 · Entitlement Required ─────────────────────────────────────────
      case KazaUIState.entitlementRequired:
        return _scaffold(KazaEntitlementRequiredState(
          onViewPlans: () => Navigator.pop(context),
          onMoreInfo: () => Navigator.pop(context),
        ));

      // ── 07 · Offline ──────────────────────────────────────────────────────
      case KazaUIState.offline:
        // Si tenemos datos pre-cargados, mostrarlos con banner offline
        if (preloadedProperty != null) {
          return _withOfflineBanner(context, ref, preloadedProperty!);
        }
        return _scaffold(KazaOfflineState(
          onRetry: () => ref.invalidate(propertyStateProvider(propertyId)),
          onViewSaved: () => Navigator.pop(context),
        ));

      // ── 09 · Unknown ──────────────────────────────────────────────────────
      case KazaUIState.unknown:
        return _scaffold(KazaUnknownState(
          onExploreOtherZones: () => Navigator.pop(context),
        ));

      // ── 05 · Permission Required ──────────────────────────────────────────
      case KazaUIState.permissionRequired:
        return _scaffold(const KazaPermissionRequiredState());

      // ── 12 · Deep Link Reauth ─────────────────────────────────────────────
      case KazaUIState.deepLinkReauthorization:
        return _scaffold(const KazaDeepLinkReauthState());

      // ── 10 · Confirmation Required (no aplica en ficha) ───────────────────
      case KazaUIState.confirmationRequired:
      case KazaUIState.loading:
        return _scaffold(const KazaLoadingState());
    }
  }

  // ── Helper: scaffold envolvente ────────────────────────────────────────────
  Widget _scaffold(Widget body) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: KazaTheme.azulKaza,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(child: body),
    );
  }

  // ── Partial Data: ficha + banner ───────────────────────────────────────────
  Widget _withPartialBanner(
    BuildContext context,
    WidgetRef ref,
    PropertyMapItem property,
    String? message,
  ) {
    return Column(
      children: [
        // Banner de advertencia sticky en la parte superior
        Material(
          color: KazaTheme.semanticWarning,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message ?? 'Información parcial — algunos datos pueden variar.',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.invalidate(propertyStateProvider(propertyId)),
                  child: const Text('Actualizar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: PropertyDetailScreen(property: property)),
      ],
    );
  }

  // ── Offline: ficha + banner sin conexión ───────────────────────────────────
  Widget _withOfflineBanner(
    BuildContext context,
    WidgetRef ref,
    PropertyMapItem property,
  ) {
    return Column(
      children: [
        Material(
          color: KazaTheme.n700,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Sin conexión — Mostrando datos guardados localmente.',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.invalidate(propertyStateProvider(propertyId)),
                  child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: PropertyDetailScreen(property: property)),
      ],
    );
  }
}
