// U05 — Modelos de KAZA Trust (Verificación de Identidad)
// Reglas canónicas del spec:
// - La verificación es opcional, gradual, personal e intransferible
// - Niveles: Básico, Estándar, Avanzado (personal) + Organización (independiente)
// - Estados: No iniciada, En proceso, En revisión, Verificada, Rechazada, Requiere info, Expirada
// - El badge público no expone documentos, domicilio, biometría ni evidencias sensibles

enum TrustLevel {
  none,      // No iniciada
  basic,     // Nivel 1 - Básico (solo email confirmado + datos personales)
  standard,  // Nivel 2 - Estándar (con documento de identidad)
  advanced,  // Nivel 3 - Avanzado (para profesionales)
  organization, // Nivel 4 - Organización (flujo independiente)
}

enum TrustStatus {
  notStarted,
  inProgress,
  underReview,
  verified,
  rejected,
  requiresInfo,
  expired,
}

extension TrustLevelX on TrustLevel {
  String get label {
    switch (this) {
      case TrustLevel.none: return 'Sin verificación';
      case TrustLevel.basic: return 'Básico';
      case TrustLevel.standard: return 'Estándar';
      case TrustLevel.advanced: return 'Avanzado';
      case TrustLevel.organization: return 'Organización';
    }
  }

  String get description {
    switch (this) {
      case TrustLevel.none: return '';
      case TrustLevel.basic:
        return 'Confirma tu identidad personal de forma básica. Incluye nombre completo, fecha de nacimiento y correo verificado.';
      case TrustLevel.standard:
        return 'Verificación con documento oficial. Incluye todo lo del Nivel Básico más documento de identidad y selfie.';
      case TrustLevel.advanced:
        return 'Para profesionales e inmobiliarias. Incluye todo lo del Nivel Estándar más relación con organización.';
      case TrustLevel.organization:
        return 'Verificación de organizaciones y empresas. Incluye documentación legal de la org y validación especializada.';
    }
  }

  String get badgeLabel {
    switch (this) {
      case TrustLevel.none: return 'Sin verificar';
      case TrustLevel.basic: return 'Verificado Básico';
      case TrustLevel.standard: return 'Verificado Estándar';
      case TrustLevel.advanced: return 'Verificado Avanzado';
      case TrustLevel.organization: return 'Org. Verificada';
    }
  }

  List<String> get includes {
    switch (this) {
      case TrustLevel.none: return [];
      case TrustLevel.basic: return [
        'Nombre completo',
        'Fecha de nacimiento',
        'Correo verificado',
      ];
      case TrustLevel.standard: return [
        'Todo lo del Nivel Básico',
        'Número de identidad (CI/Pasaporte)',
        'Foto del documento oficial',
        'Selfie con documento',
        'Validación automática',
      ];
      case TrustLevel.advanced: return [
        'Todo lo del Nivel Estándar',
        'Licencia o matrícula profesional (opcional)',
        'Validación manual (si aplica)',
      ];
      case TrustLevel.organization: return [
        'Todo lo del Nivel Avanzado',
        'Documentación legal de la organización',
        'Rol dentro de la organización',
        'Validación manual especializada',
      ];
    }
  }
}

extension TrustStatusX on TrustStatus {
  String get label {
    switch (this) {
      case TrustStatus.notStarted: return 'No iniciada';
      case TrustStatus.inProgress: return 'En proceso';
      case TrustStatus.underReview: return 'En revisión';
      case TrustStatus.verified: return 'Verificada';
      case TrustStatus.rejected: return 'Rechazada';
      case TrustStatus.requiresInfo: return 'Requiere información';
      case TrustStatus.expired: return 'Expirada';
    }
  }
}

class TrustVerification {
  final String id;
  final TrustLevel level;
  final TrustStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;

  const TrustVerification({
    required this.id,
    required this.level,
    required this.status,
    this.submittedAt,
    this.verifiedAt,
    this.expiresAt,
    this.rejectionReason,
  });
}

// Estado de la UI durante el flujo de verificación
class TrustFlowState {
  // Datos básicos
  final String fullName;
  final String birthDate;
  final String email;
  // Nivel seleccionado
  final TrustLevel selectedLevel;
  // Documentos
  final bool docUploaded;
  final bool selfieUploaded;
  // Paso actual
  final int currentStep;

  const TrustFlowState({
    this.fullName = '',
    this.birthDate = '',
    this.email = '',
    this.selectedLevel = TrustLevel.basic,
    this.docUploaded = false,
    this.selfieUploaded = false,
    this.currentStep = 0,
  });

  TrustFlowState copyWith({
    String? fullName,
    String? birthDate,
    String? email,
    TrustLevel? selectedLevel,
    bool? docUploaded,
    bool? selfieUploaded,
    int? currentStep,
  }) => TrustFlowState(
    fullName: fullName ?? this.fullName,
    birthDate: birthDate ?? this.birthDate,
    email: email ?? this.email,
    selectedLevel: selectedLevel ?? this.selectedLevel,
    docUploaded: docUploaded ?? this.docUploaded,
    selfieUploaded: selfieUploaded ?? this.selfieUploaded,
    currentStep: currentStep ?? this.currentStep,
  );
}
