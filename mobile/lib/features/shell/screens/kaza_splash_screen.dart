// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_logo_widget.dart';

/// 🚀 KAZA Splash Screen — Design System Maestro B26
///
/// Pantalla de bienvenida con:
/// - Fondo Navy (#0F1F2E)
/// - Logo animado KAZA (GIF looping)
/// - Tagline "Más que un lugar."
/// - Pills de valores de marca
/// - Transición automática al mapa después de 2.8s
class KazaSplashScreen extends StatefulWidget {
  const KazaSplashScreen({super.key});

  @override
  State<KazaSplashScreen> createState() => _KazaSplashScreenState();
}

class _KazaSplashScreenState extends State<KazaSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pillsController;

  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _pillsFade;

  @override
  void initState() {
    super.initState();

    // Status bar transparente sobre fondo oscuro
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );

    // Animaciones
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pillsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoFade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _taglineFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _pillsFade = CurvedAnimation(parent: _pillsController, curve: Curves.easeOut);

    // Secuencia de animación
    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    _slideController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _pillsController.forward();

    // Esperar que el GIF completa su primer ciclo (~2.5s)
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    await _navigateAfterSplash();
  }

  /// Determina a dónde navegar después del splash:
  /// - Usuario autenticado SIN onboarding → /login (flujo U02 + U03)
  /// - Usuario autenticado CON onboarding completo → /map
  /// - Sin sesión (invitado) → /map
  Future<void> _navigateAfterSplash() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session == null) {
        // No hay sesión — modo invitado, ir al mapa
        if (mounted) context.go('/map');
        return;
      }

      // Hay sesión — verificar si completó onboarding en profiles
      final userId = session.user.id;
      final response = await supabase
          .from('profiles')
          .select('onboarding_status')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      final status = response?['onboarding_status'] as String?;

      // COMPLETED o SKIPPED = ya pasó por el flujo, ir al mapa
      if (status == 'COMPLETED' || status == 'SKIPPED') {
        context.go('/map');
      } else {
        // Cuenta nueva o onboarding incompleto → flujo U02 → U03
        context.go('/login');
      }
    } catch (_) {
      // Si hay cualquier error de red, ir al mapa de todas formas
      if (mounted) context.go('/map');
    }
  }


  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.azulKaza,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // ── Fondo con gradiente Navy ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF1A3150),
                    KazaTheme.azulKaza,
                    const Color(0xFF080F18),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Coral accent glow (top-right) ─────────────────────────
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      KazaTheme.coralKaza.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Contenido principal ───────────────────────────────────
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Logo animado GIF
                      SlideTransition(
                        position: _logoSlide,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: Column(
                            children: [
                              const KazaSplashLogo(),
                              const SizedBox(height: 16),

                              // Tagline
                              FadeTransition(
                                opacity: _taglineFade,
                                child: Text(
                                  'Más que un lugar.',
                                  style: KazaTheme.bodyLarge(
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Pills de valores de marca
                      FadeTransition(
                        opacity: _pillsFade,
                        child: _buildBrandPills(),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),

            // ── Indicador de carga (bottom) ───────────────────────────
            Positioned(
              bottom: 40 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _pillsFade,
                child: Column(
                  children: [
                    // Progress dots animados
                    _AnimatedDots(),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando experiencia...',
                      style: KazaTheme.label(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandPills() {
    final pills = [
      {'icon': Icons.verified_outlined, 'text': 'Datos verificados'},
      {'icon': Icons.lock_outline, 'text': 'Privado y seguro'},
      {'icon': Icons.accessibility_new_outlined, 'text': 'WCAG 2.2 AA'},
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: pills.map((p) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(p['icon'] as IconData, size: 13, color: KazaTheme.coralKaza),
              const SizedBox(width: 6),
              Text(
                p['text'] as String,
                style: KazaTheme.label(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 🔵 Tres puntos pulsantes para indicar carga
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final animValue = ((_controller.value - delay) % 1.0).abs();
            final scale = 1.0 + 0.4 * (1 - (animValue * 2 - 1).abs());
            final opacity = 0.3 + 0.7 * (1 - (animValue * 2 - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale.clamp(1.0, 1.4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: KazaTheme.coralKaza.withValues(alpha: opacity.clamp(0.3, 1.0)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
