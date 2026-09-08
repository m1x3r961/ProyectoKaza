import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement_models.dart';

final achievementsProvider = FutureProvider<List<UserAchievement>>((ref) async {
  // Mock data para probar la UI según U12-A.1
  await Future.delayed(const Duration(milliseconds: 500));

  final catalog = [
    Achievement(
      id: 'a1b2c3d4',
      code: 'OPS-01.01',
      name: 'Primera Venta',
      description: 'Cerraste tu primera operación en KAZA.',
      type: AchievementType.seriesMilestone,
      iconName: 'star',
      colorHex: '#FFD700',
    ),
    Achievement(
      id: 'b2c3d4e5',
      code: 'OPS-01.02',
      name: 'Vendedor Recurrente',
      description: 'Has completado 5 operaciones exitosas.',
      type: AchievementType.seriesMilestone,
      iconName: 'trending_up',
      colorHex: '#C0C0C0',
    ),
    Achievement(
      id: 'c3d4e5f6',
      code: 'IND-01',
      name: 'Perfil Perfecto',
      description: 'Completaste el 100% de tu perfil KAZA.',
      type: AchievementType.individual,
      iconName: 'person_check',
      colorHex: '#4CAF50',
    ),
    Achievement(
      id: 'd4e5f6a7',
      code: 'IND-02',
      name: 'Fotógrafo KAZA',
      description: 'Has subido más de 100 fotos en tus propiedades.',
      type: AchievementType.individual,
      iconName: 'camera_alt',
      colorHex: '#2196F3',
    ),
  ];

  return [
    UserAchievement(
      id: '1',
      userId: 'test_user',
      achievement: catalog[0],
      status: AchievementStatus.awarded,
      timestampAwarded: DateTime.now().subtract(const Duration(days: 10)),
    ),
    UserAchievement(
      id: '2',
      userId: 'test_user',
      achievement: catalog[2],
      status: AchievementStatus.awarded,
      timestampAwarded: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserAchievement(
      id: '3',
      userId: 'test_user',
      achievement: catalog[1],
      status: AchievementStatus.pending,
    ),
  ];
});
