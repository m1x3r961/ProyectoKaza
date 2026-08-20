import 'package:flutter/material.dart';

/// Categorías de entidades financieras
enum FinancialEntityType { bank, cooperative, financial, government }

/// Estado de una solicitud de financiamiento en KAZA (Mock/Handoff)
enum FinancingRequestStatus { sent, evaluating, approved, rejected, canceled }

/// Modelo que representa a una entidad financiera y sus condiciones de crédito
class FinancialEntity {
  final String id;
  final String name;
  final String logoUrl;
  final FinancialEntityType type;
  final double referenceRate; // Ej: 7.50
  final int maxTermYears; // Ej: 20
  final String currency; // Ej: 'USD', 'BOB'
  final String creditType; // Ej: 'Hipotecario'
  final Color brandColor;

  const FinancialEntity({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.type,
    required this.referenceRate,
    required this.maxTermYears,
    required this.currency,
    required this.creditType,
    this.brandColor = Colors.blue,
  });

  String get typeLabel {
    switch (type) {
      case FinancialEntityType.bank:
        return 'Bancos';
      case FinancialEntityType.cooperative:
        return 'Cooperativas';
      case FinancialEntityType.financial:
        return 'Financieras';
      case FinancialEntityType.government:
        return 'Gobierno';
    }
  }
}

/// Modelo que representa una solicitud de financiamiento (Handoff)
class FinancingRequest {
  final String id;
  final FinancialEntity entity;
  final DateTime dateSent;
  final FinancingRequestStatus status;
  final double requestedAmount;

  const FinancingRequest({
    required this.id,
    required this.entity,
    required this.dateSent,
    required this.status,
    required this.requestedAmount,
  });

  String get statusLabel {
    switch (status) {
      case FinancingRequestStatus.sent:
        return 'Enviada';
      case FinancingRequestStatus.evaluating:
        return 'En evaluación';
      case FinancingRequestStatus.approved:
        return 'Aprobada';
      case FinancingRequestStatus.rejected:
        return 'Rechazada';
      case FinancingRequestStatus.canceled:
        return 'Cancelada';
    }
  }

  Color get statusColor {
    switch (status) {
      case FinancingRequestStatus.sent:
        return Colors.blue;
      case FinancingRequestStatus.evaluating:
        return Colors.orange;
      case FinancingRequestStatus.approved:
        return Colors.green;
      case FinancingRequestStatus.rejected:
      case FinancingRequestStatus.canceled:
        return Colors.red;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────

final List<FinancialEntity> mockEntities = [
  const FinancialEntity(
    id: 'bcp',
    name: 'Banco de Crédito BCP',
    logoUrl: 'assets/images/banks/bcp.png',
    type: FinancialEntityType.bank,
    referenceRate: 7.50,
    maxTermYears: 20,
    currency: 'USD',
    creditType: 'Hipotecario',
    brandColor: Color(0xFF003B71), // Azul BCP
  ),
  const FinancialEntity(
    id: 'bg',
    name: 'Banco Ganadero',
    logoUrl: 'assets/images/banks/ganadero.png',
    type: FinancialEntityType.bank,
    referenceRate: 7.90,
    maxTermYears: 20,
    currency: 'USD',
    creditType: 'Hipotecario',
    brandColor: Color(0xFF007A33), // Verde
  ),
  const FinancialEntity(
    id: 'ecofuturo',
    name: 'Ecofuturo',
    logoUrl: 'assets/images/banks/ecofuturo.png',
    type: FinancialEntityType.bank,
    referenceRate: 8.10,
    maxTermYears: 20,
    currency: 'USD',
    creditType: 'Hipotecario',
    brandColor: Color(0xFF8DC63F), // Verde claro
  ),
  const FinancialEntity(
    id: 'bancosol',
    name: 'Crédito de Vivienda (BancoSol)',
    logoUrl: 'assets/images/banks/bancosol.png',
    type: FinancialEntityType.bank,
    referenceRate: 7.20,
    maxTermYears: 20,
    currency: 'USD',
    creditType: 'Hipotecario',
    brandColor: Color(0xFFED7102), // Naranja
  ),
  const FinancialEntity(
    id: 'laprimera',
    name: 'Mutual La Primera',
    logoUrl: 'assets/images/banks/laprimera.png',
    type: FinancialEntityType.cooperative,
    referenceRate: 8.50,
    maxTermYears: 15,
    currency: 'USD',
    creditType: 'Hipotecario',
    brandColor: Color(0xFFD32F2F), // Rojo
  ),
];

final List<FinancingRequest> mockRequests = [
  FinancingRequest(
    id: 'req-1',
    entity: mockEntities[0], // BCP
    dateSent: DateTime.now().subtract(const Duration(days: 2)),
    status: FinancingRequestStatus.evaluating,
    requestedAmount: 125000,
  ),
  FinancingRequest(
    id: 'req-2',
    entity: mockEntities[3], // BancoSol
    dateSent: DateTime.now().subtract(const Duration(days: 15)),
    status: FinancingRequestStatus.approved,
    requestedAmount: 95000,
  ),
];
