class ProjectModel {
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
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.ownerId,
    this.orgId,
    required this.name,
    this.description,
    required this.projectType,
    required this.status,
    required this.totalUnits,
    required this.soldUnits,
    required this.reservedUnits,
    required this.availableUnits,
    required this.totalAreaM2,
    required this.estimatedInvestment,
    this.startDate,
    this.estimatedEndDate,
    required this.progressPct,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      ownerId: json['owner_id'],
      orgId: json['org_id'],
      name: json['name'],
      description: json['description'],
      projectType: json['project_type'] ?? 'RESIDENCIAL',
      status: json['status'] ?? 'IDEA',
      totalUnits: json['total_units'] ?? 0,
      soldUnits: json['sold_units'] ?? 0,
      reservedUnits: json['reserved_units'] ?? 0,
      availableUnits: json['available_units'] ?? 0,
      totalAreaM2: (json['total_area_m2'] ?? 0).toDouble(),
      estimatedInvestment: (json['estimated_investment'] ?? 0).toDouble(),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      estimatedEndDate: json['estimated_end_date'] != null ? DateTime.parse(json['estimated_end_date']) : null,
      progressPct: (json['progress_pct'] ?? 0).toDouble(),
      city: json['city'],
      address: json['address'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'project_type': projectType,
      'status': status,
      'total_units': totalUnits,
      'sold_units': soldUnits,
      'reserved_units': reservedUnits,
      'available_units': availableUnits,
      'total_area_m2': totalAreaM2,
      'estimated_investment': estimatedInvestment,
      'start_date': startDate?.toIso8601String(),
      'estimated_end_date': estimatedEndDate?.toIso8601String(),
      'progress_pct': progressPct,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
