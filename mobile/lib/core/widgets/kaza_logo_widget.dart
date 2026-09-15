// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app/theme/kaza_theme.dart';

/// 🎬 KAZA Animated Logo Widget — Design System Maestro B26
///
/// Muestra el logo animado KAZA usando el GIF generado desde kaza.mp4.
/// Fallback: kaza_logo_primary.png (logo primario con símbolo + wordmark) si el GIF no carga.
///
/// Uso:
///   KazaAnimatedLogo()               // Tamaño por defecto (200×67)
///   KazaAnimatedLogo(width: 120)     // Tamaño personalizado
///   KazaAnimatedLogo(useGif: false)  // Fuerza el logo estático primario
class KazaAnimatedLogo extends StatelessWidget {
  final double width;
  final double? height;
  final BoxFit fit;
  final bool useGif;

  const KazaAnimatedLogo({
    super.key,
    this.width = 200,
    this.height,
    this.fit = BoxFit.contain,
    this.useGif = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useGif) {
      return Image.asset(
        'assets/images/kaza_logo.gif',
        width: width,
        height: height ?? width,
        fit: fit,
      );
    }
    return _fallbackLogo();
  }

  Widget _fallbackLogo() {
    return Image.asset(
      'assets/images/kaza_logo_primary.png',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _textLogo(),
    );
  }

  Widget _textLogo() {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'K',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: KazaTheme.coralKaza,
            ),
          ),
          TextSpan(
            text: 'AZA',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: KazaTheme.azulKaza,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎬 KAZA App Bar Logo — versión compacta para AppBar
/// Tamaño optimizado para barras de navegación (ancho ~100px)
class KazaAppBarLogo extends StatelessWidget {
  const KazaAppBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const KazaAnimatedLogo(
      width: 100,
      height: 36,
      fit: BoxFit.contain,
    );
  }
}

/// 🎬 KAZA Splash Logo — versión para splash screen sobre fondo oscuro/navy
/// Muestra el símbolo con colores originales (coral) + wordmark "KAZA" en blanco.
class KazaSplashLogo extends StatelessWidget {
  const KazaSplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Símbolo KAZA con sus colores naturales (coral)
        Image.asset(
          'assets/images/kaza_symbol.png',
          width: 56,
          height: 56,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56),
        ),
        const SizedBox(width: 14),
        // Wordmark en blanco para fondo oscuro
        const Text(
          'KAZA',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

/// 🎬 KAZA Symbol Logo — solo el símbolo (ícono) sin wordmark
/// Ideal para espacios compactos: loaders, marcadores de mapa, etc.
class KazaSymbolLogo extends StatelessWidget {
  final double size;
  const KazaSymbolLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/kaza_symbol.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
