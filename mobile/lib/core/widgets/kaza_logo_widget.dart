// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app/theme/kaza_theme.dart';

/// 🎬 KAZA Animated Logo Widget — Design System Maestro B26
///
/// Muestra el logo animado KAZA usando el GIF generado desde kaza.mp4.
/// Fallback: logo.png estático si el GIF no carga.
///
/// Uso:
///   KazaAnimatedLogo()               // Tamaño por defecto (200×67)
///   KazaAnimatedLogo(width: 120)     // Tamaño personalizado
///   KazaAnimatedLogo(dark: true)     // Sobre fondo oscuro (usa logo.png blanco)
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
        height: height,
        fit: fit,
      );
    }
    return _fallbackLogo();
  }

  Widget _fallbackLogo() {
    return Image.asset(
      'assets/images/logo.png',
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

/// 🎬 KAZA Splash Logo — versión grande para splash screen (ancho ~240px)
class KazaSplashLogo extends StatelessWidget {
  const KazaSplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const KazaAnimatedLogo(
      width: 240,
      height: 80,
      fit: BoxFit.contain,
    );
  }
}
