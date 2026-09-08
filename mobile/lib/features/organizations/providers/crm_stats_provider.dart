import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import 'organizations_provider.dart';
import '../models/organization_models.dart';

class CrmStats {
  final String orgName;
  final int propertiesCount;
  final int totalViews;
  final int membersCount;

  CrmStats({
    required this.orgName,
    required this.propertiesCount,
    required this.totalViews,
    required this.membersCount,
  });
}

final crmStatsProvider = FutureProvider.autoDispose<CrmStats?>((ref) async {
  final authState = ref.watch(kazaAuthProvider);
  if (!authState.isAuthenticated || authState.userId == null) return null;

  final orgsState = ref.watch(organizationsProvider);
  if (orgsState.myOrgs.isEmpty) return null;

  // Tomamos la primera organización para el Dashboard de forma predeterminada
  final org = orgsState.myOrgs.first;

  int propsCount = 0;
  int views = 0;
  int members = 0;

  try {
    // Fetch propiedades de la organización
    final propsResponse = await SupabaseConfig.client
        .from('properties')
        .select('id, views_count')
        .eq('organization_id', org.id);
        
    final List propsList = propsResponse as List;
    propsCount = propsList.length;
    views = propsList.fold<int>(0, (sum, p) => sum + ((p['views_count'] as int?) ?? 0));

    // Fetch cantidad de miembros
    final membersResponse = await SupabaseConfig.client
        .from('organization_memberships')
        .select('id')
        .eq('organization_id', org.id);
        
    final List membersList = membersResponse as List;
    members = membersList.length;

  } catch (e) {
    // Log error, keep counts at 0
  }

  return CrmStats(
    orgName: org.name,
    propertiesCount: propsCount,
    totalViews: views,
    membersCount: members,
  );
});
