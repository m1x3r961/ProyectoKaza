import 'package:flutter/material.dart';

enum AchievementType { individual, seriesMilestone, collection, meta, limitedTemplate }
enum AchievementStatus { pending, validated, awarded }

class Achievement {
  final String id;
  final String code;
  final String name;
  final String description;
  final AchievementType type;
  final String iconName;
  final String colorHex;

  Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    required this.iconName,
    required this.colorHex,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: _parseType(json['achievement_type']),
      iconName: json['icon_name'] ?? 'emoji_events',
      colorHex: json['color_hex'] ?? '#4CAF50',
    );
  }

  static AchievementType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'SERIES_MILESTONE': return AchievementType.seriesMilestone;
      case 'COLLECTION': return AchievementType.collection;
      case 'META': return AchievementType.meta;
      case 'LIMITED_TEMPLATE': return AchievementType.limitedTemplate;
      case 'INDIVIDUAL':
      default:
        return AchievementType.individual;
    }
  }

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.green;
  }

  IconData get iconData {
    switch (iconName) {
      case 'star': return Icons.star;
      case 'trending_up': return Icons.trending_up;
      case 'person_check': return Icons.how_to_reg;
      case 'camera_alt': return Icons.camera_alt;
      default: return Icons.emoji_events;
    }
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final Achievement achievement;
  final AchievementStatus status;
  final DateTime? timestampAwarded;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievement,
    required this.status,
    this.timestampAwarded,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      achievement: Achievement.fromJson(json['achievements_catalog'] ?? {}),
      status: _parseStatus(json['status']),
      timestampAwarded: json['timestamp_awarded'] != null ? DateTime.parse(json['timestamp_awarded']) : null,
    );
  }

  static AchievementStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'VALIDATED': return AchievementStatus.validated;
      case 'AWARDED': return AchievementStatus.awarded;
      case 'PENDING':
      default:
        return AchievementStatus.pending;
    }
  }
}
