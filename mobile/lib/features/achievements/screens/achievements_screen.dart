import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/achievement_models.dart';
import '../providers/achievements_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Sistema de Logros', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: KazaTheme.textPrimary),
      ),
      body: achievementsAsync.when(
        data: (userAchievements) {
          final awarded = userAchievements.where((a) => a.status == AchievementStatus.awarded).toList();
          final pending = userAchievements.where((a) => a.status != AchievementStatus.awarded).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(awarded.length),
                      const SizedBox(height: 32),
                      const Text('Logros Desbloqueados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAchievementCard(awarded[index]),
                    childCount: awarded.length,
                  ),
                ),
              ),
              if (pending.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: const Text('En Progreso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 40),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAchievementCard(pending[index]),
                      childCount: pending.length,
                    ),
                  ),
                ),
              ]
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: KazaTheme.primaryCoral)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeader(int unlockedCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KazaTheme.n100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: KazaTheme.accentGold, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tu Colección', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 4),
                Text('$unlockedCount Logros', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: KazaTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(UserAchievement ua) {
    final ach = ua.achievement;
    final isAwarded = ua.status == AchievementStatus.awarded;

    return Container(
      decoration: BoxDecoration(
        color: isAwarded ? Colors.white : KazaTheme.n000,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAwarded ? ach.color.withValues(alpha: 0.5) : KazaTheme.glassBorder, width: isAwarded ? 2 : 1),
        boxShadow: isAwarded ? [
          BoxShadow(
            color: ach.color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAwarded ? ach.color.withValues(alpha: 0.1) : KazaTheme.n100,
              shape: BoxShape.circle,
            ),
            child: Icon(ach.iconData, color: isAwarded ? ach.color : KazaTheme.textMuted, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            ach.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 14, 
              color: isAwarded ? KazaTheme.textPrimary : KazaTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (isAwarded && ua.timestampAwarded != null)
            Text(
              DateFormat('dd MMM, yyyy').format(ua.timestampAwarded!),
              style: const TextStyle(fontSize: 10, color: KazaTheme.textMuted),
            )
          else if (!isAwarded)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: KazaTheme.n100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Pendiente', style: TextStyle(fontSize: 10, color: KazaTheme.textSecondary, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }
}
