import 'package:flutter/material.dart';

enum CollaborationMode { coBrokerage, participation, team, punctual }
enum CollaborationStatus { draft, invitationSent, active, completed, cancelled }
enum MemberRole { owner, admin, agent, collaborator }
enum MemberStatus { pending, accepted, rejected }

class CollaborationMember {
  final String id;
  final String userId;
  final String userName;
  final String userRoleTitle;
  final String? avatarUrl;
  final MemberRole role;
  final MemberStatus status;
  final double commissionPercentage;

  CollaborationMember({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRoleTitle,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.commissionPercentage,
  });
}

class Collaboration {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final double propertyPrice;
  final String? propertyImage;
  final CollaborationMode mode;
  final CollaborationStatus status;
  final String? scope;
  final bool requiresAgreement;
  final double totalCommissionValue;
  final List<CollaborationMember> members;

  Collaboration({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyPrice,
    this.propertyImage,
    required this.mode,
    required this.status,
    this.scope,
    required this.requiresAgreement,
    required this.totalCommissionValue,
    required this.members,
  });

  String get modeDisplay {
    switch (mode) {
      case CollaborationMode.coBrokerage: return 'Co-corretaje';
      case CollaborationMode.participation: return 'Participación en operación';
      case CollaborationMode.team: return 'Equipo de trabajo';
      case CollaborationMode.punctual: return 'Colaboración puntual';
    }
  }
}
