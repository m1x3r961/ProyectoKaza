import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
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
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        state = state
            .copyWith(isLoading: false, myOrgs: [], pendingInvitations: []);
        return;
      }

      // Fetch organizations via memberships
      // NOTA: Usar 'legal_name' o 'name' según el esquema final
      final data = await SupabaseConfig.client
          .from('organization_memberships')
          .select(
              'role_name, organizations(id, legal_name, description, logo_url, website, contact_email, contact_phone, city, address, org_type, created_at)')
          .eq('user_id', userId);

      final orgs = <KazaOrganization>[];
      for (final m in (data as List)) {
        final org = m['organizations'] as Map<String, dynamic>?;
        if (org != null) {
          orgs.add(KazaOrganization.fromJson({
            ...org,
            'name': org['legal_name'],
            'my_role': m['role_name'] ?? 'member',
            'members_count': 0,
          }));
        }
      }

      final invites = await SupabaseConfig.client
          .from('organization_invitations')
          .select('id, role_name, created_at, expires_at')
          .eq('status', 'PENDING')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .limit(100);
      final pendingInvites = invites
          .map((inv) => OrgInvitation(
              id: inv['id'] as String,
              orgName: 'Invitación a organización',
              invitedByName: 'Administrador de organización',
              role: parseOrgRole(inv['role_name']),
              status: InvitationStatus.pending,
              createdAt: DateTime.parse(inv['created_at']),
              expiresAt: DateTime.parse(inv['expires_at'])))
          .toList();
      if (!mounted) return;
      state = state.copyWith(
        myOrgs: orgs,
        pendingInvitations: pendingInvites,
        isLoading: false,
      );
    } catch (e) {
      if (mounted)
        state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Crear una nueva organización
  Future<String?> createOrganization({
    required String name,
    String? description,
    String? website,
    String? logoUrl,
    String? contactEmail,
    String? contactPhone,
    String? city,
    String? address,
    String orgType = 'DEVELOPER',
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return 'No estás autenticado.';

      await ApiClient().request('/api/organizations', method: 'POST', body: {
        'legal_name': name,
        'org_type': orgType,
        if (description != null) 'description': description,
        if (website != null) 'website': website,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (contactEmail != null) 'contact_email': contactEmail,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (city != null) 'city': city,
        if (address != null) 'address': address,
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
      await ApiClient().request('/api/invitations/respond',
          method: 'POST',
          body: {'code': code.trim().toUpperCase(), 'accept': true});
      await load();
      return null;
    } catch (e) {
      return 'Código inválido o expirado. Verifica e intenta de nuevo.';
    }
  }

  /// Aceptar invitación por email
  Future<String?> acceptInvitation(String invitationId) async {
    try {
      await ApiClient().request('/api/invitations/respond',
          method: 'POST', body: {'id': invitationId, 'accept': true});
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Rechazar invitación
  Future<String?> rejectInvitation(String invitationId) async {
    try {
      await ApiClient().request('/api/invitations/respond',
          method: 'POST', body: {'id': invitationId, 'accept': false});
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
  ref.watch(kazaAuthProvider);
  return OrganizationsNotifier();
});
