import 'package:flutter/material.dart';
import '../../app/theme/kaza_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEV11-E · KAZA REPRESENTATIVE STATES · v0.1
// ─────────────────────────────────────────────────────────────────────────────
// Estados representativos del sistema para asegurar claridad,
// confianza y recuperación — Parte del Prototipo KAZA · P03
//
// Principios:
//   ✅ Estados explícitos y predecibles
//   ✅ Mensajes claros y accionables
//   ✅ Sin bloqueos sin salida
//   ✅ Accesibles y comprensibles
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// 01 · LOADING STATE
// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla de carga mientras KAZA prepara el contenido.
class KazaLoadingState extends StatelessWidget {
  final String message;

  const KazaLoadingState({
    super.key,
    this.message = 'Preparando el mapa…',
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: _KazaSpinnerIcon(),
      title: 'Cargando KAZA',
      subtitle: message,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 02 · EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

/// No se encontraron resultados para la búsqueda actual.
class KazaEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onAdjustFilters;
  final VoidCallback? onNewSearch;

  const KazaEmptyState({
    super.key,
    this.title = 'No encontramos propiedades',
    this.subtitle = 'Intenta ajustar los filtros o ampliar la búsqueda.',
    this.onAdjustFilters,
    this.onNewSearch,
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(Icons.search_off_rounded, size: 56, color: KazaTheme.n300),
      title: title,
      subtitle: subtitle,
      primaryAction: onAdjustFilters != null
          ? _KazaStateButton(
              label: 'Ajustar filtros',
              onTap: onAdjustFilters!,
              style: _KazaButtonStyle.primary,
            )
          : null,
      secondaryAction: onNewSearch != null
          ? _KazaStateButton(
              label: 'Iniciar búsqueda',
              onTap: onNewSearch!,
              style: _KazaButtonStyle.ghost,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 03 · ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────

/// Error inesperado al cargar o procesar información.
class KazaErrorState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const KazaErrorState({
    super.key,
    this.title = 'Algo salió mal',
    this.subtitle = 'No pudimos cargar la información. Inténtalo nuevamente.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(Icons.error_outline_rounded, size: 56, color: KazaTheme.semanticError),
      title: title,
      subtitle: subtitle,
      primaryAction: onRetry != null
          ? _KazaStateButton(
              label: 'Solucionar',
              onTap: onRetry!,
              style: _KazaButtonStyle.destructive,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 04 · RESTRICTED STATE
// ─────────────────────────────────────────────────────────────────────────────

/// El contenido no está disponible en la zona o región del usuario.
class KazaRestrictedState extends StatelessWidget {
  final VoidCallback? onExploreOtherZones;
  final VoidCallback? onMoreInfo;

  const KazaRestrictedState({
    super.key,
    this.onExploreOtherZones,
    this.onMoreInfo,
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(Icons.lock_outline_rounded, size: 56, color: KazaTheme.n300),
      title: 'Contenido no disponible',
      subtitle: 'Este contenido no está disponible en tu zona o región.',
      primaryAction: onExploreOtherZones != null
          ? _KazaStateButton(
              label: 'Explorar otras zonas',
              onTap: onExploreOtherZones!,
              style: _KazaButtonStyle.primary,
            )
          : null,
      secondaryAction: onMoreInfo != null
          ? _KazaStateButton(
              label: 'Más información',
              onTap: onMoreInfo!,
              style: _KazaButtonStyle.ghost,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 05 · PERMISSION REQUIRED STATE
// ─────────────────────────────────────────────────────────────────────────────

/// Se requiere un permiso del dispositivo (ej: ubicación).
class KazaPermissionRequiredState extends StatelessWidget {
  final String permissionName;
  final String description;
  final VoidCallback? onGoToSettings;
  final VoidCallback? onDismiss;

  const KazaPermissionRequiredState({
    super.key,
    this.permissionName = 'ubicación',
    this.description =
        'Para mostrarte propiedades cercanas activa el permiso de ubicación.',
    this.onGoToSettings,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(Icons.location_on_outlined, size: 56, color: KazaTheme.azulKaza),
      title: 'Necesitamos tu $permissionName',
      subtitle: description,
      primaryAction: onGoToSettings != null
          ? _KazaStateButton(
              label: 'Ir a Configuración',
              onTap: onGoToSettings!,
              style: _KazaButtonStyle.primary,
            )
          : null,
      secondaryAction: onDismiss != null
          ? _KazaStateButton(
              label: 'Ahora no',
              onTap: onDismiss!,
              style: _KazaButtonStyle.ghost,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 06 · ENTITLEMENT REQUIRED STATE
// ─────────────────────────────────────────────────────────────────────────────

/// La función requiere un plan Plus, Pro o Business.
class KazaEntitlementRequiredState extends StatelessWidget {
  final VoidCallback? onViewPlans;
  final VoidCallback? onMoreInfo;

  const KazaEntitlementRequiredState({
    super.key,
    this.onViewPlans,
    this.onMoreInfo,
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(Icons.star_outline_rounded, size: 56, color: KazaTheme.accentGold),
      title: 'Función exclusiva',
      subtitle:
          'Esta función está disponible para usuarios Plus, Pro o Business.',
      primaryAction: onViewPlans != null
          ? _KazaStateButton(
              label: 'Ver planes',
              onTap: onViewPlans!,
              style: _KazaButtonStyle.gold,
            )
          : null,
      secondaryAction: onMoreInfo != null
          ? _KazaStateButton(
              label: 'Más información',
              onTap: onMoreInfo!,
              style: _KazaButtonStyle.ghost,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 07 · OFFLINE STATE
// ─────────────────────────────────────────────────────────────────────────────

/// No hay conexión a internet disponible.
class KazaOfflineState extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onViewSaved;

  const KazaOfflineState({
    super.key,
    this.onRetry,
    this.onViewSaved,
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(Icons.cloud_off_outlined, size: 56, color: KazaTheme.n300),
      title: 'Sin conexión',
      subtitle: 'Verifica tu conexión a internet e intenta nuevamente.',
      primaryAction: onRetry != null
          ? _KazaStateButton(
              label: 'Solucionar',
              onTap: onRetry!,
              style: _KazaButtonStyle.primary,
            )
          : null,
      secondaryAction: onViewSaved != null
          ? _KazaStateButton(
              label: 'Ver contenido guardado',
              onTap: onViewSaved!,
              style: _KazaButtonStyle.ghost,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 08 · PARTIAL DATA STATE
// ─────────────────────────────────────────────────────────────────────────────

/// Información disponible pero incompleta o desactualizada.
class KazaPartialDataState extends StatelessWidget {
  final String staleSince;
  final VoidCallback? onRefresh;

  const KazaPartialDataState({
    super.key,
    this.staleSince = '7 días',
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(Icons.data_usage_rounded, size: 56, color: KazaTheme.semanticWarning),
      title: 'Información parcial',
      subtitle: 'Mostramos información con datos incompletos.',
      badge: _KazaWarningBadge(
        text: 'Actualizado hace $staleSince — Algunos números pueden variar.',
      ),
      primaryAction: onRefresh != null
          ? _KazaStateButton(
              label: 'Actualizar datos',
              onTap: onRefresh!,
              style: _KazaButtonStyle.primary,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 09 · UNKNOWN STATE
// ─────────────────────────────────────────────────────────────────────────────

/// Información desconocida o no disponible aún.
class KazaUnknownState extends StatelessWidget {
  final VoidCallback? onExploreOtherZones;

  const KazaUnknownState({
    super.key,
    this.onExploreOtherZones,
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(Icons.help_outline_rounded, size: 56, color: KazaTheme.n300),
      title: 'Información no disponible',
      subtitle: 'Aún no tenemos datos para esta propiedad o zona.',
      primaryAction: onExploreOtherZones != null
          ? _KazaStateButton(
              label: 'Explorar otras zonas',
              onTap: onExploreOtherZones!,
              style: _KazaButtonStyle.primary,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10 · CONFIRMATION REQUIRED STATE
// ─────────────────────────────────────────────────────────────────────────────

/// Diálogo de confirmación para acciones sensibles e irreversibles.
class KazaConfirmationDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;

  const KazaConfirmationDialog({
    super.key,
    required this.title,
    required this.body,
    required this.onConfirm,
    required this.onCancel,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: KazaTheme.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDestructive
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              size: 40,
              color: isDestructive
                  ? KazaTheme.semanticError
                  : KazaTheme.semanticInfo,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: KazaTheme.azulKaza,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                color: KazaTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: isDestructive
                      ? KazaTheme.semanticError
                      : KazaTheme.azulKaza,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel,
                child: Text(
                  cancelLabel,
                  style: const TextStyle(
                    color: KazaTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 11 · BACKEND SUCCESS STATE
// ─────────────────────────────────────────────────────────────────────────────

/// Operación backend completada correctamente.
class KazaSuccessState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onPrimaryAction;
  final String primaryLabel;
  final VoidCallback? onSecondaryAction;
  final String secondaryLabel;

  const KazaSuccessState({
    super.key,
    this.title = '¡Listo!',
    this.subtitle = 'Tu publicación fue publicada correctamente.',
    this.onPrimaryAction,
    this.primaryLabel = 'Ver publicación',
    this.onSecondaryAction,
    this.secondaryLabel = 'Compartir',
  });

  @override
  Widget build(BuildContext context) {
    return _KazaStateScaffold(
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        size: 56,
        color: KazaTheme.semanticSuccess,
      ),
      title: title,
      subtitle: subtitle,
      primaryAction: onPrimaryAction != null
          ? _KazaStateButton(
              label: primaryLabel,
              onTap: onPrimaryAction!,
              style: _KazaButtonStyle.success,
            )
          : null,
      secondaryAction: onSecondaryAction != null
          ? _KazaStateButton(
              label: secondaryLabel,
              onTap: onSecondaryAction!,
              style: _KazaButtonStyle.ghost,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 12 · DEEP LINK REAUTHORIZATION STATE
// ─────────────────────────────────────────────────────────────────────────────

/// El enlace profundo requiere revalidación de acceso.
class KazaDeepLinkReauthState extends StatelessWidget {
  const KazaDeepLinkReauthState({super.key});

  @override
  Widget build(BuildContext context) {
    return const _KazaStateScaffold(
      icon: Icon(Icons.link_rounded, size: 56, color: KazaTheme.semanticInfo),
      title: 'Revalidando acceso',
      subtitle: 'Estamos verificando tu acceso a este contenido.',
      badge: _KazaInfoBadge(
        text: 'Este proceso es automático, por favor espera.',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Scaffold base compartido por todos los estados
// ─────────────────────────────────────────────────────────────────────────────

class _KazaStateScaffold extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final _KazaStateButton? primaryAction;
  final _KazaStateButton? secondaryAction;
  final Widget? badge;

  const _KazaStateScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.primaryAction,
    this.secondaryAction,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: KazaTheme.azulKaza,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: KazaTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (badge != null) ...[
              const SizedBox(height: 12),
              badge!,
            ],
            if (primaryAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: primaryAction!),
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: secondaryAction!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Spinner animado para estado Loading
// ─────────────────────────────────────────────────────────────────────────────

class _KazaSpinnerIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 56,
      height: 56,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: KazaTheme.coralKaza,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Estilos de botones de acción en estados
// ─────────────────────────────────────────────────────────────────────────────

enum _KazaButtonStyle { primary, ghost, destructive, success, gold }

class _KazaStateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final _KazaButtonStyle style;

  const _KazaStateButton({
    required this.label,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case _KazaButtonStyle.primary:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: KazaTheme.azulKaza,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        );
      case _KazaButtonStyle.destructive:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: KazaTheme.semanticError,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        );
      case _KazaButtonStyle.success:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: KazaTheme.semanticSuccess,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        );
      case _KazaButtonStyle.gold:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: KazaTheme.accentGold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        );
      case _KazaButtonStyle.ghost:
        return TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: KazaTheme.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Badge de advertencia (estado 08 · Partial Data)
// ─────────────────────────────────────────────────────────────────────────────

class _KazaWarningBadge extends StatelessWidget {
  final String text;
  const _KazaWarningBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KazaTheme.semanticWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: KazaTheme.semanticWarning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: KazaTheme.semanticWarning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: KazaTheme.semanticWarning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Badge informativo (estado 12 · Deep Link Reauth)
// ─────────────────────────────────────────────────────────────────────────────

class _KazaInfoBadge extends StatelessWidget {
  final String text;
  const _KazaInfoBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KazaTheme.semanticInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: KazaTheme.semanticInfo.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: KazaTheme.semanticInfo,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: KazaTheme.semanticInfo,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
