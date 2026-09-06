/// Modelos Dart para U08 — Desarrolladora
/// Mapeados 1:1 con las tablas de Supabase

class ProfessionalProfile {
  final String id;
  final String role;
  final String? bio;
  final String? phone;
  final String? companyName;
  final String? specialty;
  final int yearsExperience;
  final List<String> languages;
  final double rating;
  final int totalReviews;
  final bool isVerified;

  ProfessionalProfile({
    required this.id,
    required this.role,
    this.bio,
    this.phone,
    this.companyName,
    this.specialty,
    this.yearsExperience = 0,
    this.languages = const ['ES'],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
  });

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) {
    return ProfessionalProfile(
      id: json['id'],
      role: json['role'] ?? 'AGENT',
      bio: json['bio'],
      phone: json['phone'],
      companyName: json['company_name'],
      specialty: json['specialty'],
      yearsExperience: json['years_experience'] ?? 0,
      languages: json['languages'] != null 
          ? List<String>.from(json['languages']) 
          : ['ES'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isVerified: json['is_verified'] ?? false,
    );
  }
}

class DevProject {
  final String id;
  final String ownerId;
  final String? orgId;
  final String name;
  final String? description;
  final String projectType;
  final String status;
  final int totalUnits;
  final int soldUnits;
  final int reservedUnits;
  final int availableUnits;
  final double totalAreaM2;
  final double estimatedInvestment;
  final DateTime? startDate;
  final DateTime? estimatedEndDate;
  final double progressPct;
  final String? city;
  final String? address;

  DevProject({
    required this.id,
    required this.ownerId,
    this.orgId,
    required this.name,
    this.description,
    required this.projectType,
    required this.status,
    this.totalUnits = 0,
    this.soldUnits = 0,
    this.reservedUnits = 0,
    this.availableUnits = 0,
    this.totalAreaM2 = 0,
    this.estimatedInvestment = 0,
    this.startDate,
    this.estimatedEndDate,
    this.progressPct = 0,
    this.city,
    this.address,
  });

  factory DevProject.fromJson(Map<String, dynamic> json) {
    return DevProject(
      id: json['id'],
      ownerId: json['owner_id'],
      orgId: json['org_id'],
      name: json['name'] ?? 'Sin nombre',
      description: json['description'],
      projectType: json['project_type'] ?? 'RESIDENCIAL',
      status: json['status'] ?? 'IDEA',
      totalUnits: json['total_units'] ?? 0,
      soldUnits: json['sold_units'] ?? 0,
      reservedUnits: json['reserved_units'] ?? 0,
      availableUnits: json['available_units'] ?? 0,
      totalAreaM2: (json['total_area_m2'] ?? 0).toDouble(),
      estimatedInvestment: (json['estimated_investment'] ?? 0).toDouble(),
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      estimatedEndDate: json['estimated_end_date'] != null ? DateTime.tryParse(json['estimated_end_date']) : null,
      progressPct: (json['progress_pct'] ?? 0).toDouble(),
      city: json['city'],
      address: json['address'],
    );
  }

  /// Porcentaje de ventas sobre total
  double get salesPct => totalUnits > 0 ? (soldUnits / totalUnits) * 100 : 0;
  
  /// Ingresos proyectados (vendidas + reservadas)
  String get statusLabel {
    const labels = {
      'IDEA': 'Idea',
      'PLANIFICACION': 'Planificación',
      'LEGALIZACION': 'Legalización',
      'CONSTRUCCION': 'Construcción',
      'COMERCIALIZACION': 'Comercialización',
      'ENTREGA': 'Entrega',
      'POST_VENTA': 'Post-Venta',
    };
    return labels[status] ?? status;
  }
}

class DevProjectStage {
  final String id;
  final String projectId;
  final String name;
  final int stageOrder;
  final String status;
  final double progressPct;
  final DateTime? startDate;
  final DateTime? endDate;

  DevProjectStage({
    required this.id,
    required this.projectId,
    required this.name,
    required this.stageOrder,
    required this.status,
    this.progressPct = 0,
    this.startDate,
    this.endDate,
  });

  factory DevProjectStage.fromJson(Map<String, dynamic> json) {
    return DevProjectStage(
      id: json['id'],
      projectId: json['project_id'],
      name: json['name'] ?? '',
      stageOrder: json['stage_order'] ?? 0,
      status: json['status'] ?? 'PENDIENTE',
      progressPct: (json['progress_pct'] ?? 0).toDouble(),
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
    );
  }
}

class DevUnit {
  final String id;
  final String projectId;
  final String unitCode;
  final String typology;
  final double areaM2;
  final int bedrooms;
  final int bathrooms;
  final int floorNumber;
  final double priceUsd;
  final String status;
  final String? buyerName;
  final String? buyerContact;
  final DateTime? saleDate;

  DevUnit({
    required this.id,
    required this.projectId,
    required this.unitCode,
    required this.typology,
    this.areaM2 = 0,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.floorNumber = 1,
    this.priceUsd = 0,
    required this.status,
    this.buyerName,
    this.buyerContact,
    this.saleDate,
  });

  factory DevUnit.fromJson(Map<String, dynamic> json) {
    return DevUnit(
      id: json['id'],
      projectId: json['project_id'],
      unitCode: json['unit_code'] ?? '',
      typology: json['typology'] ?? 'DEPARTAMENTO',
      areaM2: (json['area_m2'] ?? 0).toDouble(),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      floorNumber: json['floor_number'] ?? 1,
      priceUsd: (json['price_usd'] ?? 0).toDouble(),
      status: json['status'] ?? 'DISPONIBLE',
      buyerName: json['buyer_name'],
      buyerContact: json['buyer_contact'],
      saleDate: json['sale_date'] != null ? DateTime.tryParse(json['sale_date']) : null,
    );
  }
}

class DevDocument {
  final String id;
  final String projectId;
  final String name;
  final String docType;
  final String? fileUrl;
  final DateTime? uploadedAt;

  DevDocument({
    required this.id,
    required this.projectId,
    required this.name,
    required this.docType,
    this.fileUrl,
    this.uploadedAt,
  });

  factory DevDocument.fromJson(Map<String, dynamic> json) {
    return DevDocument(
      id: json['id'],
      projectId: json['project_id'],
      name: json['name'] ?? '',
      docType: json['doc_type'] ?? 'OTRO',
      fileUrl: json['file_url'],
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at']) : null,
    );
  }
}

class DevFinancialRecord {
  final String id;
  final String projectId;
  final String recordType; // INGRESO | EGRESO
  final String category;
  final double amount;
  final String? description;
  final DateTime? recordDate;

  DevFinancialRecord({
    required this.id,
    required this.projectId,
    required this.recordType,
    required this.category,
    required this.amount,
    this.description,
    this.recordDate,
  });

  factory DevFinancialRecord.fromJson(Map<String, dynamic> json) {
    return DevFinancialRecord(
      id: json['id'],
      projectId: json['project_id'],
      recordType: json['record_type'] ?? 'INGRESO',
      category: json['category'] ?? 'OTRO',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'],
      recordDate: json['record_date'] != null ? DateTime.tryParse(json['record_date']) : null,
    );
  }
}
