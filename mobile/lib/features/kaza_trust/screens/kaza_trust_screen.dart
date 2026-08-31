import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../models/trust_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// U05 — KAZA TRUST: Pantalla principal del flujo de verificación
// Pasos: Intro → Elegir nivel → Datos personales → Documentos → Revisión → Listo
// ─────────────────────────────────────────────────────────────────────────────

class KazaTrustScreen extends ConsumerStatefulWidget {
  const KazaTrustScreen({super.key});

  @override
  ConsumerState<KazaTrustScreen> createState() => _KazaTrustScreenState();
}

class _KazaTrustScreenState extends ConsumerState<KazaTrustScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  TrustFlowState _flow = const TrustFlowState();
  bool _isSubmitting = false;
  int _currentPage = 0;

  // Controllers for personal data form
  final _nameCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _docNumberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Pre-fill email from current user
    final user = SupabaseConfig.client.auth.currentUser;
    if (user?.email != null) {
      _emailCtrl.text = user!.email!;
      _flow = _flow.copyWith(email: user.email!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _emailCtrl.dispose();
    _docNumberCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _fadeCtrl.reset();
    _pageController
        .animateToPage(page,
            duration: const Duration(milliseconds: 320), curve: Curves.easeOut)
        .then((_) {
      setState(() => _currentPage = page);
      _fadeCtrl.forward();
    });
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);
    _goTo(4); // pantalla "en revisión"
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      await SupabaseConfig.client.from('trust_verifications').upsert({
        'user_id': userId,
        'level': _flow.selectedLevel.name,
        'status': 'UNDER_REVIEW',
        'full_name': _nameCtrl.text.trim(),
        'birth_date': _birthCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'doc_number': _docNumberCtrl.text.trim().isEmpty
            ? null
            : _docNumberCtrl.text.trim(),
        'submitted_at': DateTime.now().toIso8601String(),
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _goTo(5); // ¡Enviado!
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _goTo(2); // volver a datos personales
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al enviar: $e'),
          backgroundColor: KazaTheme.coralKaza,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: KazaTheme.textPrimary),
          onPressed: () {
            if (_currentPage > 0 && _currentPage < 4) {
              _goTo(_currentPage - 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _buildStepIndicator(),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildPage00Intro(),
          _buildPage01ChooseLevel(),
          _buildPage02PersonalData(),
          _buildPage03Documents(),
          _buildPage04UnderReview(),
          _buildPage05Done(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    if (_currentPage >= 4) return const SizedBox.shrink();
    final labels = ['Inicio', 'Nivel', 'Datos', 'Documentos'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final done = i < _currentPage;
        final active = i == _currentPage;
        return Row(
          children: [
            Container(
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: done
                    ? KazaTheme.azulKaza.withValues(alpha: 0.4)
                    : active
                        ? KazaTheme.azulKaza
                        : KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(4),
              ),
              child: active
                  ? null
                  : null,
            ),
            if (i < 3) const SizedBox(width: 4),
          ],
        );
      }),
    );
  }

  // ── PÁGINA 00: INTRO ──────────────────────────────────────────────────────
  Widget _buildPage00Intro() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        children: [
          // Header con badge KAZA Trust
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F1F2E), Color(0xFF1A3A5C)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('KAZA TRUST',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Verifica tu\nidentidad',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: KazaTheme.textPrimary,
                height: 1.15),
          ),
          const SizedBox(height: 12),
          const Text(
            'KAZA Trust es el sistema de confianza de KAZA. Verifica tu identidad para generar más confianza en la comunidad y acceder a más capacidades.',
            style: TextStyle(
                color: KazaTheme.textSecondary, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Principios clave
          _buildPrincipleItem(Icons.volunteer_activism_outlined, 'Opcional',
              'Puedes usar KAZA sin verificar. Verifica cuando lo necesites.'),
          _buildPrincipleItem(Icons.trending_up_rounded, 'Gradual',
              'Puedes verificar por partes según tus necesidades.'),
          _buildPrincipleItem(Icons.lock_outline_rounded, 'Privado',
              'KAZA no comparte tus datos personales. Solo el badge es público.'),
          _buildPrincipleItem(Icons.person_outline_rounded, 'Personal e intransferible',
              'La verificación corresponde solo a tu cuenta.'),

          const SizedBox(height: 32),

          // Beneficios
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: KazaTheme.azulKaza.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KazaTheme.azulKaza.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Para qué sirve verificar?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: KazaTheme.azulKaza,
                        fontSize: 15)),
                const SizedBox(height: 12),
                ...[
                  'Genera más confianza con otros usuarios',
                  'Accede a más capacidades y beneficios',
                  'Publica y opera con más credibilidad',
                  'Protege tu cuenta y previene fraudes',
                  'Mejora tu reputación en KAZA',
                ].map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: KazaTheme.azulKaza, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(b,
                                  style: const TextStyle(
                                      color: KazaTheme.textSecondary,
                                      fontSize: 13))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildPrimaryButton('Comenzar verificación', () => _goTo(1)),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ahora no',
                  style: TextStyle(color: KazaTheme.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipleItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: KazaTheme.azulKaza.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: KazaTheme.azulKaza, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: KazaTheme.textPrimary,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: KazaTheme.textMuted, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PÁGINA 01: ELEGIR NIVEL ───────────────────────────────────────────────
  Widget _buildPage01ChooseLevel() {
    final levels = [TrustLevel.basic, TrustLevel.standard, TrustLevel.advanced];

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        children: [
          const Text('Elige tu nivel\nde verificación',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.textPrimary,
                  height: 1.2)),
          const SizedBox(height: 6),
          const Text('Puedes empezar por lo básico y ir avanzando.',
              style: TextStyle(color: KazaTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          ...levels.map((lvl) => _buildLevelCard(lvl)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KazaTheme.grisClaro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: KazaTheme.textMuted, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No todos los niveles necesitan todos los pasos.',
                    style:
                        TextStyle(color: KazaTheme.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
              'Continuar con ${_flow.selectedLevel.label}',
              () => _goTo(2)),
        ],
      ),
    );
  }

  Widget _buildLevelCard(TrustLevel lvl) {
    final isSelected = _flow.selectedLevel == lvl;
    final colors = {
      TrustLevel.basic: KazaTheme.azulKaza,
      TrustLevel.standard: const Color(0xFF7C4DFF),
      TrustLevel.advanced: KazaTheme.coralKaza,
    };
    final color = colors[lvl] ?? KazaTheme.azulKaza;
    final icons = {
      TrustLevel.basic: Icons.shield_outlined,
      TrustLevel.standard: Icons.verified_user_outlined,
      TrustLevel.advanced: Icons.workspace_premium_outlined,
    };

    return GestureDetector(
      onTap: () => setState(() => _flow = _flow.copyWith(selectedLevel: lvl)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : KazaTheme.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icons[lvl], color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lvl.label,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : KazaTheme.textPrimary,
                            fontSize: 16)),
                  ],
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                        color: isSelected ? color : KazaTheme.textMuted,
                        width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 13)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...lvl.includes.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_rounded,
                          size: 14,
                          color: isSelected ? color : KazaTheme.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(item,
                            style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? KazaTheme.textPrimary
                                    : KazaTheme.textMuted)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── PÁGINA 02: DATOS PERSONALES ───────────────────────────────────────────
  Widget _buildPage02PersonalData() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        children: [
          const Text('Información personal',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text(
            'Esta información es solo para verificar tu identidad. No será visible públicamente.',
            style: TextStyle(
                color: KazaTheme.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 28),

          // Nombre completo
          _buildLabel('Nombre completo *'),
          const SizedBox(height: 6),
          _buildInput(
              ctrl: _nameCtrl,
              hint: 'Ej: Juan Carlos Pérez Rodríguez',
              icon: Icons.person_outline_rounded),
          const SizedBox(height: 18),

          // Fecha de nacimiento
          _buildLabel('Fecha de nacimiento *'),
          const SizedBox(height: 6),
          _buildInput(
              ctrl: _birthCtrl,
              hint: 'DD/MM/AAAA',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.datetime),
          const SizedBox(height: 18),

          // Email (pre-llenado, no editable si ya tiene sesión)
          _buildLabel('Correo electrónico verificado *'),
          const SizedBox(height: 6),
          _buildInput(
              ctrl: _emailCtrl,
              hint: 'tucorreo@ejemplo.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 8),
          if (_emailCtrl.text.isNotEmpty)
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: KazaTheme.azulKaza.withValues(alpha: 0.7), size: 14),
                const SizedBox(width: 6),
                const Text('Correo vinculado a tu cuenta',
                    style: TextStyle(
                        color: KazaTheme.textMuted, fontSize: 12)),
              ],
            ),

          // Número de documento — solo para Estándar/Avanzado
          if (_flow.selectedLevel == TrustLevel.standard ||
              _flow.selectedLevel == TrustLevel.advanced) ...[
            const SizedBox(height: 18),
            _buildLabel('Número de identidad (CI/Pasaporte) *'),
            const SizedBox(height: 6),
            _buildInput(
                ctrl: _docNumberCtrl,
                hint: 'Ej: 12345678',
                icon: Icons.badge_outlined),
          ],

          const SizedBox(height: 32),
          _buildPrimaryButton('Continuar', () {
            if (_nameCtrl.text.trim().isEmpty ||
                _birthCtrl.text.trim().isEmpty ||
                _emailCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Por favor completa todos los campos requeridos.')),
              );
              return;
            }
            _flow = _flow.copyWith(
              fullName: _nameCtrl.text.trim(),
              birthDate: _birthCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
            );
            // Si es Básico, saltamos documentos y vamos directo a enviar
            if (_flow.selectedLevel == TrustLevel.basic) {
              _submitVerification();
            } else {
              _goTo(3);
            }
          }),
        ],
      ),
    );
  }

  // ── PÁGINA 03: DOCUMENTOS (solo para Estándar / Avanzado) ─────────────────
  Widget _buildPage03Documents() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        children: [
          const Text('Sube tus documentos',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Los documentos son procesados de forma segura y no serán visibles en tu perfil público.',
            style: TextStyle(
                color: KazaTheme.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 28),

          // Documento de identidad
          _buildUploadCard(
            icon: Icons.credit_card_outlined,
            title: 'Documento de identidad',
            subtitle: 'CI, cédula, pasaporte u otro documento oficial',
            uploaded: _flow.docUploaded,
            onTap: () => setState(
                () => _flow = _flow.copyWith(docUploaded: !_flow.docUploaded)),
          ),
          const SizedBox(height: 14),

          // Selfie con documento
          _buildUploadCard(
            icon: Icons.face_rounded,
            title: 'Selfie con documento',
            subtitle: 'Una foto tuya sosteniendo tu documento de identidad',
            uploaded: _flow.selfieUploaded,
            onTap: () => setState(() =>
                _flow = _flow.copyWith(selfieUploaded: !_flow.selfieUploaded)),
          ),

          const SizedBox(height: 24),

          // Aviso de privacidad
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KazaTheme.grisClaro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: KazaTheme.textMuted, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'KAZA no comparte tus documentos con terceros. Solo se usan para la validación de identidad.',
                    style: TextStyle(
                        color: KazaTheme.textMuted, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _buildPrimaryButton(
            'Enviar para revisión',
            (_flow.docUploaded && _flow.selfieUploaded)
                ? _submitVerification
                : null,
          ),
          if (!_flow.docUploaded || !_flow.selfieUploaded)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Debes subir ambos documentos para continuar.',
                  style: TextStyle(color: KazaTheme.textMuted, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool uploaded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: uploaded
              ? KazaTheme.azulKaza.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: uploaded ? KazaTheme.azulKaza : KazaTheme.glassBorder,
            width: uploaded ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: uploaded
                    ? KazaTheme.azulKaza.withValues(alpha: 0.12)
                    : KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(uploaded ? Icons.check_circle_rounded : icon,
                  color: uploaded ? KazaTheme.azulKaza : KazaTheme.textMuted,
                  size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: uploaded
                              ? KazaTheme.azulKaza
                              : KazaTheme.textPrimary,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: KazaTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              uploaded
                  ? Icons.check_rounded
                  : Icons.cloud_upload_outlined,
              color: uploaded ? KazaTheme.azulKaza : KazaTheme.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── PÁGINA 04: EN REVISIÓN ────────────────────────────────────────────────
  Widget _buildPage04UnderReview() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                    color: KazaTheme.azulKaza, strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Enviando información...',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: KazaTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Estamos procesando tus datos de forma segura.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KazaTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── PÁGINA 05: ¡ENVIADO! ──────────────────────────────────────────────────
  Widget _buildPage05Done() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: KazaTheme.azulKaza, size: 44),
            ),
            const SizedBox(height: 28),
            const Text('¡Solicitud enviada!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: KazaTheme.textPrimary)),
            const SizedBox(height: 12),
            Text(
              'Tu solicitud de verificación ${_flow.selectedLevel.label} está en revisión.\n\nNormalmente procesamos las verificaciones en 24–48 horas. Te notificaremos por correo cuando esté lista.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: KazaTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),

            // Estado visual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text('Estado: En revisión',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildPrimaryButton('Volver al perfil', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  // ── HELPERS COMPARTIDOS ───────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: KazaTheme.textPrimary,
            fontSize: 14));
  }

  Widget _buildInput({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: KazaTheme.textMuted),
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

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KazaTheme.azulKaza,
          foregroundColor: Colors.white,
          disabledBackgroundColor: KazaTheme.grisClaro,
          disabledForegroundColor: KazaTheme.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
