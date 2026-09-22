import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_config.dart';
import '../models/project_model.dart';
import '../models/project_unit_model.dart';

final crmProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final supabase = SupabaseConfig.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await supabase
      .from('dev_projects')
      .select('*')
      .eq('owner_id', userId)
      .order('created_at', ascending: false);

  return (response as List).map((json) => ProjectModel.fromJson(json)).toList();
});

final projectUnitsProvider = FutureProvider.family<List<ProjectUnitModel>, String>((ref, projectId) async {
  final supabase = SupabaseConfig.client;

  final response = await supabase
      .from('dev_units')
      .select('*')
      .eq('project_id', projectId)
      .order('unit_code', ascending: true);

  return (response as List).map((json) => ProjectUnitModel.fromJson(json)).toList();
});
