import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// U03 — PERFIL DE USO  (Formas de Uso KAZA)
//
// Spec: Las formas de uso NO son roles. El usuario puede elegir una, varias
// o ninguna. Pueden cambiarse desde Ajustes. No asignan permisos ni capacidades.
// ─────────────────────────────────────────────────────────────────────────────

/// Modelo de opción de uso
class _UsageOption {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;

  const _UsageOption({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

const List<_UsageOption> _kUsageOptions = [
  _UsageOption(
    id: 'SEARCH',
    icon: Icons.search_rounded,
    title: 'Buscar propiedades',
    subtitle:
        'Quiero encontrar propiedades para comprar, alquilar o invertir.',
  ),
  _UsageOption(
    id: 'PUBLISH',
    icon: Icons.home_work_outlined,
    title: 'Publicar propiedades',
    subtitle:
        'Quiero publicar mis propiedades para venderlas o alquilarlas.',
  ),
  _UsageOption(
    id: 'PROFESSIONAL',
    icon: Icons.work_outline_rounded,
    title: 'Trabajar como profesional inmobiliario',
    subtitle:
        'Quiero gestionar propiedades de clientes y conectar con ellos.',
  ),
  _UsageOption(
    id: 'ORGANIZATION',
    icon: Icons.business_outlined,
    title: 'Representar una empresa u organización',
    subtitle:
        'Quiero gestionar propiedades desde una empresa o entidad que represento.',
  ),
];

/// U03 — Pantalla de Perfil de Uso (Onboarding)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final Set<String> _selectedIds = {};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _animCtrl.reset();
    _pageController
        .animateToPage(page,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut)
        .then((_) {
      setState(() => _currentPage = page);
      _animCtrl.forward();
    });
  }

  void _toggleOption(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _saveAndFinish() async {
    _goTo(3); // pantalla "personalizando"

    try {
      final authState = ref.read(kazaAuthProvider);
      await SupabaseConfig.client.from('user_profiles').upsert({
        'id': SupabaseConfig.client.auth.currentUser?.id,
        'email': authState.email ?? '',
        'usage_modes': _selectedIds.toList(),
        'onboarding_status': 'COMPLETED',
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _goTo(4); // ¡Listo!
    } catch (e) {
      if (mounted) {
        _goTo(1); // volver a selección
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No pudimos guardar tu perfil. Intenta de nuevo.'),
            backgroundColor: KazaTheme.coralKaza,
          ),
        );
      }
    }
  }

  Future<void> _skipAndFinish() async {
    try {
      await SupabaseConfig.client.from('user_profiles').upsert({
        'id': SupabaseConfig.client.auth.currentUser?.id,
        'usage_modes': <String>[],
        'onboarding_status': 'SKIPPED',
      });
    } catch (_) {}
    if (mounted) context.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPage01Intro(),
                _buildPage02SelectUsage(),
                _buildPage03Confirmation(),
                _buildPage04Personalizing(),
                _buildPage05Done(),
              ],
            ),
            // Botón "Omitir" — solo visible en páginas 0-2
            if (_currentPage < 3)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: _skipAndFinish,
                  child: const Text(
                    'Omitir',
                    style: TextStyle(
                        color: KazaTheme.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── PÁGINA 01: INTRODUCCIÓN ─────────────────────────────────────────────
  Widget _buildPage01Intro() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            // Logo
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: KazaTheme.azulKaza,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('K',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('KAZA',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: KazaTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 48),
            const Text(
              '¿Cómo quieres\nusar KAZA?',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.textPrimary,
                  height: 1.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'El usuario define cómo quiere usar KAZA hoy.\n\nNo es un rol. Puedes seleccionar una, varias o ninguna opción. Puedes cambiar o agregar más en cualquier momento desde Ajustes de cuenta.',
              style: TextStyle(
                  fontSize: 15,
                  color: KazaTheme.textSecondary,
                  height: 1.5),
            ),
            const Spacer(),
            // Info chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: KazaTheme.azulKaza.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: KazaTheme.azulKaza, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Las formas de uso no asignan permisos ni determinan capacidades.',
                      style: TextStyle(
                          color: KazaTheme.azulKaza,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildPrimaryButton('Continuar', () => _goTo(1)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── PÁGINA 02: SELECCIÓN DE USOS ────────────────────────────────────────
  Widget _buildPage02SelectUsage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'Selecciona las opciones que mejor te describan',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Puedes elegir una, varias o ninguna opción.',
              style: TextStyle(color: KazaTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            // Las 4 tarjetas
            Expanded(
              child: ListView.separated(
                itemCount: _kUsageOptions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final opt = _kUsageOptions[i];
                  final isSelected = _selectedIds.contains(opt.id);
                  return _buildOptionCard(opt, isSelected);
                },
              ),
            ),
            const SizedBox(height: 16),
            // Hint: no sé aún
            Center(
              child: TextButton.icon(
                onPressed: () => _goTo(2),
                icon: const Icon(Icons.help_outline_rounded,
                    size: 18, color: KazaTheme.textMuted),
                label: const Text(
                  'No sé todavía cómo usar KAZA',
                  style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                ),
              ),
            ),
            _buildPrimaryButton(
              'Continuar',
              () => _goTo(2),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(_UsageOption opt, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleOption(opt.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? KazaTheme.azulKaza.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? KazaTheme.azulKaza : KazaTheme.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: KazaTheme.azulKaza.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? KazaTheme.azulKaza.withValues(alpha: 0.15)
                    : KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(opt.icon,
                  color: isSelected ? KazaTheme.azulKaza : KazaTheme.textMuted,
                  size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? KazaTheme.azulKaza
                          : KazaTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    opt.subtitle,
                    style: const TextStyle(
                        fontSize: 13,
                        color: KazaTheme.textMuted,
                        height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? KazaTheme.azulKaza : Colors.transparent,
                border: Border.all(
                  color: isSelected ? KazaTheme.azulKaza : KazaTheme.textMuted,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── PÁGINA 03: CONFIRMACIÓN ──────────────────────────────────────────────
  Widget _buildPage03Confirmation() {
    final selectedOptions = _kUsageOptions
        .where((o) => _selectedIds.contains(o.id))
        .toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'Resumen de lo\nseleccionado',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.textPrimary,
                  height: 1.2),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se asigna ningún permiso ni capacidad.',
              style: TextStyle(color: KazaTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            if (selectedOptions.isEmpty)
              _buildNoSelectionBanner()
            else
              ...selectedOptions.map((o) => _buildConfirmItem(o)),
            const Spacer(),
            // Recordatorio clave del spec
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.autorenew_rounded,
                      color: KazaTheme.textSecondary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Recuerda que siempre podrás cambiar o agregar tus formas de uso desde Ajustes de cuenta.',
                      style: TextStyle(
                          color: KazaTheme.textSecondary,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton('¡Perfecto! Continuar', _saveAndFinish),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => _goTo(1),
                child: const Text('Volver a editar',
                    style: TextStyle(color: KazaTheme.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelectionBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KazaTheme.grisClaro,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.explore_outlined,
              color: KazaTheme.textMuted, size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin ninguna opción',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: KazaTheme.textPrimary)),
                SizedBox(height: 4),
                Text(
                  'Podrás explorar KAZA libremente y elegir más adelante.',
                  style: TextStyle(
                      color: KazaTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmItem(_UsageOption opt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KazaTheme.azulKaza.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(opt.icon, color: KazaTheme.azulKaza, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(opt.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: KazaTheme.textPrimary,
                    fontSize: 15)),
          ),
          const Icon(Icons.check_circle_rounded,
              color: KazaTheme.azulKaza, size: 20),
        ],
      ),
    );
  }

  // ── PÁGINA 04: PERSONALIZANDO (animación de carga) ──────────────────────
  Widget _buildPage04Personalizing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: KazaTheme.azulKaza.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: KazaTheme.azulKaza,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Personalizando tu KAZA',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: KazaTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              _PersonalizingItem(
                  icon: Icons.star_outline_rounded,
                  text: 'Favoritos y recomendaciones más relevantes'),
              SizedBox(height: 10),
              _PersonalizingItem(
                  icon: Icons.flash_on_outlined,
                  text: 'Acceso rápido a lo que más te interesa'),
              SizedBox(height: 10),
              _PersonalizingItem(
                  icon: Icons.notifications_active_outlined,
                  text: 'Notificaciones según tu uso'),
            ],
          ),
        ),
      ],
    );
  }

  // ── PÁGINA 05: ¡LISTO! ──────────────────────────────────────────────────
  Widget _buildPage05Done() {
    final selectedOptions = _kUsageOptions
        .where((o) => _selectedIds.contains(o.id))
        .toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: KazaTheme.azulKaza, size: 48),
            ),
            const SizedBox(height: 28),
            const Text('¡Listo!',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: KazaTheme.textPrimary)),
            const SizedBox(height: 12),
            Text(
              selectedOptions.isEmpty
                  ? 'Tu KAZA está lista para explorar.'
                  : 'Tu experiencia KAZA está configurada para:\n${selectedOptions.map((o) => '• ${o.title}').join('\n')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: KazaTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5),
            ),
            const SizedBox(height: 40),
            _buildPrimaryButton(
              'Explorar KAZA',
              () => context.go('/map'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _goTo(1),
              child: const Text(
                '¿Cambiar mis opciones?',
                style: TextStyle(color: KazaTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KazaTheme.azulKaza,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(text,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Widget auxiliar para la pantalla de "Personalizando"
class _PersonalizingItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PersonalizingItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: KazaTheme.azulKaza, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: KazaTheme.textSecondary,
                  fontSize: 14,
                  height: 1.3)),
        ),
      ],
    );
  }
}
