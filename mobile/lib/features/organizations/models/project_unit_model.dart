class ProjectUnitModel {
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
  final DateTime createdAt;

  ProjectUnitModel({
    required this.id,
    required this.projectId,
    required this.unitCode,
    required this.typology,
    required this.areaM2,
    required this.bedrooms,
    required this.bathrooms,
    required this.floorNumber,
    required this.priceUsd,
    required this.status,
    this.buyerName,
    this.buyerContact,
    this.saleDate,
    required this.createdAt,
  });

  factory ProjectUnitModel.fromJson(Map<String, dynamic> json) {
    return ProjectUnitModel(
      id: json['id'],
      projectId: json['project_id'],
      unitCode: json['unit_code'],
      typology: json['typology'] ?? 'DEPARTAMENTO',
      areaM2: (json['area_m2'] ?? 0).toDouble(),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      floorNumber: json['floor_number'] ?? 1,
      priceUsd: (json['price_usd'] ?? 0).toDouble(),
      status: json['status'] ?? 'DISPONIBLE',
      buyerName: json['buyer_name'],
      buyerContact: json['buyer_contact'],
      saleDate: json['sale_date'] != null ? DateTime.parse(json['sale_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'unit_code': unitCode,
      'typology': typology,
      'area_m2': areaM2,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'floor_number': floorNumber,
      'price_usd': priceUsd,
      'status': status,
      'buyer_name': buyerName,
      'buyer_contact': buyerContact,
      'sale_date': saleDate?.toIso8601String(),
    };
  }
}
