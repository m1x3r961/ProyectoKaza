import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_config.dart';
import '../models/developer_models.dart';

/// 🏗️ Provider Riverpod para el módulo Desarrolladora (U08)
/// Todas las operaciones son REALES contra Supabase.

// ── Estado del módulo ────────────────────────────────────────
class DeveloperState {
  final List<DevProject> projects;
  final ProfessionalProfile? profile;
  final bool isLoading;
  final String? error;

  DeveloperState({
    this.projects = const [],
    this.profile,
    this.isLoading = false,
    this.error,
  });

  DeveloperState copyWith({
    List<DevProject>? projects,
    ProfessionalProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return DeveloperState(
      projects: projects ?? this.projects,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Estadísticas calculadas
  int get totalProjects => projects.length;
  int get activeProjects => projects.where((p) => p.status != 'POST_VENTA' && p.status != 'IDEA').length;
  int get totalUnitsSold => projects.fold(0, (sum, p) => sum + p.soldUnits);
  int get totalUnitsAll => projects.fold(0, (sum, p) => sum + p.totalUnits);
  double get totalInvestment => projects.fold(0.0, (sum, p) => sum + p.estimatedInvestment);
  double get overallSalesPct => totalUnitsAll > 0 ? (totalUnitsSold / totalUnitsAll) * 100 : 0;
}

// ── Notifier ─────────────────────────────────────────────────
class DeveloperNotifier extends StateNotifier<DeveloperState> {
  DeveloperNotifier() : super(DeveloperState());

  final _db = SupabaseConfig.client;

  /// Cargar todo: perfil profesional + proyectos
  Future<void> loadAll(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Perfil profesional
      final profileResp = await _db
          .from('professional_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      ProfessionalProfile? profile;
      if (profileResp != null) {
        profile = ProfessionalProfile.fromJson(profileResp);
      }

      // 2. Proyectos
      final projectsResp = await _db
          .from('dev_projects')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      final projects = (projectsResp as List)
          .map((j) => DevProject.fromJson(j))
          .toList();

      state = state.copyWith(
        profile: profile,
        projects: projects,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error cargando datos de desarrolladora: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Ejecutar seed de datos de ejemplo
  Future<bool> seedDemoData() async {
    try {
      await _db.rpc('fn_seed_developer_demo');
      return true;
    } catch (e) {
      debugPrint('Error en seed: $e');
      return false;
    }
  }

  /// Cargar etapas de un proyecto
  Future<List<DevProjectStage>> loadStages(String projectId) async {
    try {
      final resp = await _db
          .from('dev_project_stages')
          .select()
          .eq('project_id', projectId)
          .order('stage_order', ascending: true);
      return (resp as List).map((j) => DevProjectStage.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error cargando etapas: $e');
      return [];
    }
  }

  /// Cargar unidades de un proyecto
  Future<List<DevUnit>> loadUnits(String projectId) async {
    try {
      final resp = await _db
          .from('dev_units')
          .select()
          .eq('project_id', projectId)
          .order('unit_code', ascending: true);
      return (resp as List).map((j) => DevUnit.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error cargando unidades: $e');
      return [];
    }
  }

  /// Cargar documentos de un proyecto
  Future<List<DevDocument>> loadDocuments(String projectId) async {
    try {
      final resp = await _db
          .from('dev_documents')
          .select()
          .eq('project_id', projectId)
          .order('uploaded_at', ascending: false);
      return (resp as List).map((j) => DevDocument.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error cargando documentos: $e');
      return [];
    }
  }

  /// Cargar registros financieros de un proyecto
  Future<List<DevFinancialRecord>> loadFinancials(String projectId) async {
    try {
      final resp = await _db
          .from('dev_financial_records')
          .select()
          .eq('project_id', projectId)
          .order('record_date', ascending: false);
      return (resp as List).map((j) => DevFinancialRecord.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error cargando financieros: $e');
      return [];
    }
  }

  /// Actualizar progreso de una etapa
  Future<void> updateStageProgress(String stageId, double progressPct) async {
    try {
      String status = 'PENDIENTE';
      if (progressPct >= 100) {
        status = 'COMPLETADA';
      } else if (progressPct > 0) {
        status = 'EN_PROGRESO';
      }
      await _db.from('dev_project_stages').update({
        'progress_pct': progressPct,
        'status': status,
      }).eq('id', stageId);
    } catch (e) {
      debugPrint('Error actualizando etapa: $e');
    }
  }

  /// Crear un nuevo proyecto
  Future<String?> createProject({
    required String name,
    required String projectType,
    String? description,
    int totalUnits = 0,
    String? city,
  }) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return null;

      final resp = await _db.from('dev_projects').insert({
        'owner_id': userId,
        'name': name,
        'project_type': projectType,
        'description': description,
        'total_units': totalUnits,
        'available_units': totalUnits,
        'city': city,
      }).select('id').single();

      // Recargar proyectos
      await loadAll(userId);
      return resp['id'];
    } catch (e) {
      debugPrint('Error creando proyecto: $e');
      return null;
    }
  }
}

// ── Provider global ──────────────────────────────────────────
final developerProvider = StateNotifierProvider<DeveloperNotifier, DeveloperState>((ref) {
  return DeveloperNotifier();
});
