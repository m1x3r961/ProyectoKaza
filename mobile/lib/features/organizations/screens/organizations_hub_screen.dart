import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/organization_models.dart';
import '../providers/organizations_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// U04 — MEMBRESÍAS Y ORGANIZACIONES
// Hub de entrada (se accede desde Perfil → "Mis Organizaciones")
// ─────────────────────────────────────────────────────────────────────────────

class OrganizationsHubScreen extends ConsumerStatefulWidget {
  const OrganizationsHubScreen({super.key});

  @override
  ConsumerState<OrganizationsHubScreen> createState() =>
      _OrganizationsHubScreenState();
}

class _OrganizationsHubScreenState
    extends ConsumerState<OrganizationsHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(organizationsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizationsProvider);

    return Scaffold(
      backgroundColor: KazaTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Mis Organizaciones',
          style: TextStyle(
              color: KazaTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: KazaTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(organizationsProvider.notifier).load(),
        color: KazaTheme.azulKaza,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner explicativo (spec: U04 es opcional)
            _buildInfoBanner(),
            const SizedBox(height: 24),

            // Invitaciones pendientes
            if (state.pendingInvitations.isNotEmpty) ...[
              _buildSectionTitle(
                  'Invitaciones pendientes',
                  Icons.mail_outline_rounded,
                  KazaTheme.coralKaza),
              const SizedBox(height: 12),
              ...state.pendingInvitations
                  .map((inv) => _buildInvitationCard(inv)),
              const SizedBox(height: 24),
            ],

            // Mis organizaciones actuales
            if (state.isLoading)
              const Center(
                  child: CircularProgressIndicator(color: KazaTheme.azulKaza))
            else if (state.myOrgs.isNotEmpty) ...[
              _buildSectionTitle(
                  'Mis organizaciones', Icons.business_outlined, KazaTheme.azulKaza),
              const SizedBox(height: 12),
              ...state.myOrgs.map((org) => _buildOrgCard(org)),
              const SizedBox(height: 24),
            ] else if (!state.isLoading && state.pendingInvitations.isEmpty) ...[
              _buildEmptyState(),
              const SizedBox(height: 24),
            ],

            // Las 4 acciones del spec
            _buildSectionTitle(
                '¿Qué quieres hacer?', Icons.add_circle_outline_rounded, KazaTheme.azulKaza),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.add_business_rounded,
              color: KazaTheme.azulKaza,
              title: 'Crear una organización',
              subtitle:
                  'Soy el fundador o represento una empresa y quiero crear una nueva.',
              idealFor: ['Inmobiliarias', 'Empresas', 'Estudios', 'Equipos de trabajo'],
              onTap: () => _showCreateOrgSheet(context),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.group_add_rounded,
              color: const Color(0xFF7C4DFF),
              title: 'Unirme a una organización',
              subtitle:
                  'Ya existe una organización y quiero ingresar como miembro.',
              idealFor: ['Profesionales inmobiliarios', 'Colaboradores', 'Comercios asociados'],
              onTap: () => _showJoinByCodeSheet(context),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.mark_email_unread_outlined,
              color: KazaTheme.coralKaza,
              title: 'Tengo una invitación',
              subtitle: 'Recibí una invitación por email o por código.',
              idealFor: ['Invitaciones por email', 'Invitaciones por código', 'Invitaciones internas de KAZA'],
              onTap: () => _showInvitationSheet(context),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.person_outline_rounded,
              color: KazaTheme.textMuted,
              title: 'Continuar sin organización',
              subtitle:
                  'Prefiero usar KAZA con mi cuenta personal y elegir una organización después.',
              idealFor: [],
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 32),

            // Nota del spec: "Membresía no implica representación pública automática"
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: KazaTheme.textMuted, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pertenecer a una organización no implica representación pública automática. Puedes gestionar tus organizaciones en cualquier momento desde Ajustes → Organizaciones → Mis organizaciones.',
                      style: TextStyle(
                          color: KazaTheme.textMuted,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KazaTheme.azulKaza.withValues(alpha: 0.08),
            KazaTheme.azulKaza.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: KazaTheme.azulKaza.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.business_center_outlined,
              color: KazaTheme.azulKaza, size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Organizaciones en KAZA',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: KazaTheme.azulKaza,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  'Conecta tu cuenta personal con una o varias organizaciones. Este paso es opcional.',
                  style: TextStyle(
                      color: KazaTheme.textSecondary,
                      fontSize: 13,
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.business_outlined,
              size: 48, color: KazaTheme.textMuted),
          SizedBox(height: 12),
          Text('No perteneces a ninguna organización',
              style: TextStyle(
                  color: KazaTheme.textPrimary, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text(
            'Puedes crear una nueva o unirte a una existente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgCard(KazaOrganization org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KazaTheme.glassBorder),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Navegar al Panel Organizacional (Business Dashboard)
            context.push('/org-dashboard');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_rounded,
                      color: KazaTheme.azulKaza, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(org.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: KazaTheme.textPrimary)),
                      const SizedBox(height: 3),
                      _buildRoleBadge(org.myRole),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: KazaTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(OrgMemberRole role) {
    Color color;
    switch (role) {
      case OrgMemberRole.owner:
        color = KazaTheme.coralKaza;
        break;
      case OrgMemberRole.admin:
        color = const Color(0xFF7C4DFF);
        break;
      case OrgMemberRole.member:
        color = KazaTheme.azulKaza;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role.label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInvitationCard(OrgInvitation inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KazaTheme.coralKaza.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: KazaTheme.coralKaza.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded,
                  color: KazaTheme.coralKaza, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(inv.orgName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: KazaTheme.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Invitado por ${inv.invitedByName} como ${inv.role.label}',
            style: const TextStyle(
                color: KazaTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: KazaTheme.textMuted),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => ref
                      .read(organizationsProvider.notifier)
                      .rejectInvitation(inv.id),
                  child: const Text('Rechazar',
                      style: TextStyle(color: KazaTheme.textMuted)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KazaTheme.azulKaza,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () => ref
                      .read(organizationsProvider.notifier)
                      .acceptInvitation(inv.id),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required List<String> idealFor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KazaTheme.glassBorder),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: KazaTheme.textSecondary,
                          fontSize: 13,
                          height: 1.3)),
                  if (idealFor.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: idealFor
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(t,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM SHEETS ────────────────────────────────────────────────────────

  void _showCreateOrgSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateOrgSheet(),
    );
  }

  void _showJoinByCodeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _JoinByCodeSheet(),
    );
  }

  void _showInvitationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _InvitationInfoSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET: Crear organización
// ─────────────────────────────────────────────────────────────────────────────

class _CreateOrgSheet extends ConsumerStatefulWidget {
  const _CreateOrgSheet();

  @override
  ConsumerState<_CreateOrgSheet> createState() => _CreateOrgSheetState();
}

class _CreateOrgSheetState extends ConsumerState<_CreateOrgSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _webCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final err = await ref.read(organizationsProvider.notifier).createOrganization(
          name: name,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          website: _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim(),
        );
    if (mounted) {
      setState(() => _loading = false);
      if (err == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Organización "$name" creada con éxito!'),
            backgroundColor: KazaTheme.azulKaza,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: KazaTheme.coralKaza),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Crear organización',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text(
            'Quedarás como Propietario de la organización.',
            style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildInput(_nameCtrl, 'Nombre de la organización *', Icons.business_rounded),
          const SizedBox(height: 12),
          _buildInput(_descCtrl, 'Descripción (opcional)', Icons.description_outlined),
          const SizedBox(height: 12),
          _buildInput(_webCtrl, 'Sitio web (opcional)', Icons.link_rounded),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Crear organización',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: KazaTheme.textMuted, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KazaTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KazaTheme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KazaTheme.azulKaza, width: 2),
        ),
        filled: true,
        fillColor: KazaTheme.grisClaro,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET: Unirse por código
// ─────────────────────────────────────────────────────────────────────────────

class _JoinByCodeSheet extends ConsumerStatefulWidget {
  const _JoinByCodeSheet();

  @override
  ConsumerState<_JoinByCodeSheet> createState() => _JoinByCodeSheetState();
}

class _JoinByCodeSheetState extends ConsumerState<_JoinByCodeSheet> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    final err =
        await ref.read(organizationsProvider.notifier).joinByCode(code);
    if (mounted) {
      setState(() => _loading = false);
      if (err == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Te uniste a la organización con éxito!'),
          backgroundColor: KazaTheme.azulKaza,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: KazaTheme.coralKaza),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Unirse con código',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text(
            'El administrador de la organización te habrá compartido un código de invitación.',
            style: TextStyle(
                color: KazaTheme.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: KazaTheme.azulKaza),
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: const TextStyle(
                  color: KazaTheme.textMuted,
                  letterSpacing: 6,
                  fontSize: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KazaTheme.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KazaTheme.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: KazaTheme.azulKaza, width: 2),
              ),
              filled: true,
              fillColor: KazaTheme.grisClaro,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Unirse',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET: Información sobre invitaciones
// ─────────────────────────────────────────────────────────────────────────────

class _InvitationInfoSheet extends StatelessWidget {
  const _InvitationInfoSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.mark_email_unread_outlined,
                  color: KazaTheme.coralKaza, size: 24),
              SizedBox(width: 10),
              Text('Tengo una invitación',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: KazaTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInviteOption(
            icon: Icons.email_outlined,
            title: 'Por email',
            desc: 'Revisa tu bandeja de entrada. La invitación aparecerá automáticamente arriba en esta pantalla.',
            color: KazaTheme.coralKaza,
          ),
          const SizedBox(height: 12),
          _buildInviteOption(
            icon: Icons.pin_outlined,
            title: 'Por código',
            desc: 'Pídele el código al administrador y úsalo en "Unirse a una organización".',
            color: const Color(0xFF7C4DFF),
          ),
          const SizedBox(height: 24),
          // Estados de invitación (spec)
          const Text('Estados de invitación',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
          const SizedBox(height: 10),
          _buildStatusRow('Pendiente', 'La invitación fue enviada y aún no respondiste.', Colors.orange),
          _buildStatusRow('Aceptada', 'La invitación fue aceptada y eres miembro de la organización.', Colors.green),
          _buildStatusRow('Rechazada', 'La invitación fue rechazada.', KazaTheme.coralKaza),
          _buildStatusRow('Expirada', 'La invitación caducó sin ser respondida.', KazaTheme.textMuted),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: KazaTheme.glassBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido',
                  style: TextStyle(color: KazaTheme.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteOption(
      {required IconData icon,
      required String title,
      required String desc,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(
                        color: KazaTheme.textSecondary,
                        fontSize: 13,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: '$status: ',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  TextSpan(
                      text: desc,
                      style: const TextStyle(
                          color: KazaTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
