import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_config.dart';
import '../models/organization_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class OrganizationsState {
  final List<KazaOrganization> myOrgs;
  final List<OrgInvitation> pendingInvitations;
  final bool isLoading;
  final String? error;

  const OrganizationsState({
    this.myOrgs = const [],
    this.pendingInvitations = const [],
    this.isLoading = false,
    this.error,
  });

  OrganizationsState copyWith({
    List<KazaOrganization>? myOrgs,
    List<OrgInvitation>? pendingInvitations,
    bool? isLoading,
    String? error,
  }) =>
      OrganizationsState(
        myOrgs: myOrgs ?? this.myOrgs,
        pendingInvitations: pendingInvitations ?? this.pendingInvitations,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class OrganizationsNotifier extends StateNotifier<OrganizationsState> {
  OrganizationsNotifier() : super(const OrganizationsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, myOrgs: [], pendingInvitations: []);
        return;
      }

      // Fetch organizations via memberships
      final memberships = await SupabaseConfig.client
          .from('organization_members')
          .select('role, organizations(id, name, description, logo_url, website, created_at)')
          .eq('user_id', userId);

      final orgs = <KazaOrganization>[];
      for (final m in memberships) {
        final org = m['organizations'] as Map<String, dynamic>?;
        if (org != null) {
          orgs.add(KazaOrganization.fromJson({
            ...org,
            'my_role': m['role'] ?? 'member',
            'members_count': 0,
          }));
        }
      }

      // Fetch pending invitations
      final invites = await SupabaseConfig.client
          .from('organization_invitations')
          .select('id, role, status, created_at, expires_at, organizations(name), invited_by_profiles:invited_by(display_name)')
          .eq('invited_email', SupabaseConfig.client.auth.currentUser?.email ?? '')
          .eq('status', 'PENDING');

      final pendingInvites = <OrgInvitation>[];
      for (final inv in invites) {
        final org = inv['organizations'] as Map<String, dynamic>?;
        pendingInvites.add(OrgInvitation(
          id: inv['id'] as String,
          orgName: org?['name'] as String? ?? 'Organización',
          invitedByName: (inv['invited_by_profiles'] as Map?)
                  ?['display_name'] as String? ??
              'Un miembro',
          role: parseOrgRole(inv['role'] as String? ?? 'member'),
          status: InvitationStatus.pending,
          createdAt: DateTime.tryParse(inv['created_at'] as String? ?? '') ??
              DateTime.now(),
          expiresAt: inv['expires_at'] != null
              ? DateTime.tryParse(inv['expires_at'] as String)
              : null,
        ));
      }

      state = state.copyWith(
        myOrgs: orgs,
        pendingInvitations: pendingInvites,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Crear una nueva organización
  Future<String?> createOrganization({
    required String name,
    String? description,
    String? website,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return 'No estás autenticado.';

      final result = await SupabaseConfig.client
          .from('organizations')
          .insert({'name': name, 'description': description, 'website': website})
          .select('id')
          .single();

      final orgId = result['id'] as String;

      // Asignar rol owner al creador
      await SupabaseConfig.client.from('organization_members').insert({
        'organization_id': orgId,
        'user_id': userId,
        'role': 'owner',
      });

      await load();
      return null; // null = sin error
    } catch (e) {
      return e.toString();
    }
  }

  /// Unirse mediante código de invitación
  Future<String?> joinByCode(String code) async {
    try {
      await SupabaseConfig.client.rpc('fn_accept_invitation_by_code',
          params: {'p_code': code.trim().toUpperCase()});
      await load();
      return null;
    } catch (e) {
      return 'Código inválido o expirado. Verifica e intenta de nuevo.';
    }
  }

  /// Aceptar invitación por email
  Future<String?> acceptInvitation(String invitationId) async {
    try {
      await SupabaseConfig.client
          .from('organization_invitations')
          .update({'status': 'ACCEPTED'}).eq('id', invitationId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Rechazar invitación
  Future<String?> rejectInvitation(String invitationId) async {
    try {
      await SupabaseConfig.client
          .from('organization_invitations')
          .update({'status': 'REJECTED'}).eq('id', invitationId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final organizationsProvider =
    StateNotifierProvider<OrganizationsNotifier, OrganizationsState>((ref) {
  return OrganizationsNotifier();
});
