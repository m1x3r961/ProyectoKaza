// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: undefined_prefixed_name
import 'dart:html' as html;
import '../../../app/theme/kaza_theme.dart';

/// 🌐 TOUR 360° LOCAL — Visor esférico con imágenes panorámicas de la propiedad
///
/// En Flutter Web: embebe `web/pannellum_360.html` via iframe (HtmlElementView)
/// En Flutter nativo: muestra carrusel interactivo con InteractiveViewer 360°
class Tour360LocalScreen extends StatefulWidget {
  final String propertyTitle;
  final List<String> assetImages;

  const Tour360LocalScreen({
    super.key,
    this.propertyTitle = 'Tour Virtual 360°',
    this.assetImages = const [
      'assets/images/1.jpeg',
      'assets/images/2.jpeg',
      'assets/images/3.jpeg',
      'assets/images/4.jpeg',
      'assets/images/5.jpeg',
    ],
  });

  @override
  State<Tour360LocalScreen> createState() => _Tour360LocalScreenState();
}

class _Tour360LocalScreenState extends State<Tour360LocalScreen>
    with TickerProviderStateMixin {
  int _currentScene = 0;
  bool _transitioning = false;
  static bool _iframeRegistered = false;

  // Para el fallback nativo
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<_SceneInfo> _scenes = const [
    _SceneInfo('Entrada Principal', 'Escalera & Hall', '🏠'),
    _SceneInfo('Cocina & Comedor', 'Área gourmet', '🍳'),
    _SceneInfo('Salón Principal', 'Sala de estar', '🛋️'),
    _SceneInfo('Pasillo & Dormitorios', 'Acceso privado', '🚪'),
    _SceneInfo('Dormitorio Principal', 'Suite & closet', '🛏️'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    if (kIsWeb) {
      _registerIframe();
    }
  }

  void _registerIframe() {
    if (_iframeRegistered) return;
    _iframeRegistered = true;

    // ignore: undefined_prefixed_name
    final iframe = html.IFrameElement()
      ..src = 'pannellum_360.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..setAttribute('allow', 'fullscreen; gyroscope; accelerometer');

    ui_web.platformViewRegistry.registerViewFactory(
      'kaza-pannellum-360',
      (int viewId) => iframe,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateTo(int idx) {
    if (_transitioning || idx < 0 || idx >= widget.assetImages.length) return;
    setState(() => _transitioning = true);

    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentScene = idx);
      _pageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _fadeController.forward().then((_) {
        if (mounted) setState(() => _transitioning = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: KazaTheme.coralKaza.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.view_in_ar_rounded,
                  color: KazaTheme.coralKaza, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              widget.propertyTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: KazaTheme.coralKaza.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: KazaTheme.coralKaza.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.fiber_manual_record,
                    color: KazaTheme.coralKaza, size: 8),
                SizedBox(width: 5),
                Text('KAZA 360°',
                    style: TextStyle(
                        color: KazaTheme.coralKaza,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
      body: kIsWeb ? _buildWebView() : _buildNativeView(),
    );
  }

  // ── WEB: Pannellum en iframe ──────────────────────────────────────────────
  Widget _buildWebView() {
    return const HtmlElementView(viewType: 'kaza-pannellum-360');
  }

  // ── NATIVO: InteractiveViewer 360° con navegación ─────────────────────────
  Widget _buildNativeView() {
    final images = widget.assetImages;
    final scene = _scenes[_currentScene];
    final total = images.length;

    return Stack(
      children: [
        // Imagen actual con InteractiveViewer para arrastrar
        FadeTransition(
          opacity: _fadeAnim,
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            itemBuilder: (ctx, i) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.5,
                child: Image.asset(
                  images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),
        ),

        // HUD superior
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC0F1F2E), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                Text(scene.icon,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(scene.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      Text(scene.subtitle,
                          style: const TextStyle(
                              color: Color(0xAAFFFFFF),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${_currentScene + 1} / $total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Hint de gesto
        Positioned(
          top: 80,
          left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pan_tool_alt_outlined,
                      color: Colors.white54, size: 14),
                  SizedBox(width: 6),
                  Text('Arrastra para explorar en 360°',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),

        // Barra inferior de navegación
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xE60F1F2E), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dots + escenas
                _buildSceneThumbs(total),
                const SizedBox(height: 14),
                // Botones prev/next
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NavButton(
                      label: '← Anterior',
                      isNext: false,
                      enabled: _currentScene > 0,
                      onTap: () => _navigateTo(_currentScene - 1),
                    ),
                    const SizedBox(width: 12),
                    _NavButton(
                      label: 'Siguiente →',
                      isNext: true,
                      enabled: _currentScene < total - 1,
                      onTap: () => _navigateTo(_currentScene + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSceneThumbs(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == _currentScene;
        return GestureDetector(
          onTap: () => _navigateTo(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isActive ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? KazaTheme.coralKaza
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _scenes[i].icon,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────

class _SceneInfo {
  final String title;
  final String subtitle;
  final String icon;
  const _SceneInfo(this.title, this.subtitle, this.icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// NAV BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String label;
  final bool isNext;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.isNext,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: isNext
                ? KazaTheme.coralKaza.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: isNext
                  ? KazaTheme.coralKaza.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
