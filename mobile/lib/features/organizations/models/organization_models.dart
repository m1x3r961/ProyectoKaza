// U04 — Modelos de Membresías y Organizaciones
// Reglas canónicas del spec:
// - Persona y organización son entidades distintas
// - Roles: Propietario, Administrador, Miembro
// - Invitado NO es un rol — es un estado de invitación
// - Estados de invitación: Pendiente, Aceptada, Rechazada, Expirada
// - Una org activa debe tener al menos un Propietario

enum OrgMemberRole { owner, admin, member }

enum InvitationStatus { pending, accepted, rejected, expired }

extension OrgMemberRoleX on OrgMemberRole {
  String get label {
    switch (this) {
      case OrgMemberRole.owner:
        return 'Propietario de la organización';
      case OrgMemberRole.admin:
        return 'Administrador';
      case OrgMemberRole.member:
        return 'Miembro';
    }
  }

  String get description {
    switch (this) {
      case OrgMemberRole.owner:
        return 'Máximo control. Puede gestionar todo y asignar roles.';
      case OrgMemberRole.admin:
        return 'Gestiona miembros, publicaciones y configuración según permisos.';
      case OrgMemberRole.member:
        return 'Puede crear, editar y gestionar según permisos asignados.';
    }
  }
}

extension InvitationStatusX on InvitationStatus {
  String get label {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pendiente';
      case InvitationStatus.accepted:
        return 'Aceptada';
      case InvitationStatus.rejected:
        return 'Rechazada';
      case InvitationStatus.expired:
        return 'Expirada';
    }
  }
}

class KazaOrganization {
  final String id;
  final String name; // maps to legal_name in UI/DB mostly
  final String? description;
  final String? logoUrl;
  final String? website;
  final String? contactEmail;
  final String? contactPhone;
  final String? city;
  final String? address;
  final String? orgType;
  final OrgMemberRole myRole;
  final int membersCount;
  final DateTime createdAt;

  const KazaOrganization({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.website,
    this.contactEmail,
    this.contactPhone,
    this.city,
    this.address,
    this.orgType,
    required this.myRole,
    required this.membersCount,
    required this.createdAt,
  });

  factory KazaOrganization.fromJson(Map<String, dynamic> json) {
    return KazaOrganization(
      id: json['id'] as String,
      name: (json['name'] ?? json['legal_name'] ?? 'Organización sin nombre') as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      website: json['website'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      orgType: json['org_type'] as String?,
      myRole: parseOrgRole(json['my_role'] as String? ?? 'member'),
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'logo_url': logoUrl,
        'website': website,
      };
}

OrgMemberRole parseOrgRole(String r) {
  switch (r) {
    case 'owner':
      return OrgMemberRole.owner;
    case 'admin':
      return OrgMemberRole.admin;
    default:
      return OrgMemberRole.member;
  }
}

class OrgInvitation {
  final String id;
  final String orgName;
  final String invitedByName;
  final OrgMemberRole role;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const OrgInvitation({
    required this.id,
    required this.orgName,
    required this.invitedByName,
    required this.role,
    required this.status,
    required this.createdAt,
    this.expiresAt,
  });
}
