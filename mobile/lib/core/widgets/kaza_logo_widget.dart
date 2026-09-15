import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme/kaza_theme.dart';

// Rutas a los SVG del KAZA Wordmark Lockup 1.0
const _kSvgTagline =
    'assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Lockup_With_Tagline.svg';
const _kSvgPrimary =
    'assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Lockup_Primary.svg';
const _kSvgNegative =
    'assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Lockup_Negative_Navy.svg';
const _kSvgSymbol =
    'assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Symbol_Master.svg';

/// 🎬 KAZA Splash Logo — PNG HD con tagline, colores originales sobre fondo blanco
/// Símbolo navy + wordmark navy + tagline coral — 2048px de resolución
class KazaSplashLogo extends StatelessWidget {
  const KazaSplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/kaza_logo_tagline_hd.png',
      width: 280,
      fit: BoxFit.contain,
    );
  }
}

/// 🎬 KAZA AppBar Logo — SVG primario compacto para barras de navegación
class KazaAppBarLogo extends StatelessWidget {
  final bool dark;
  const KazaAppBarLogo({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      dark ? _kSvgNegative : _kSvgPrimary,
      height: 28,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => _FallbackLogo(dark: dark),
    );
  }
}

/// 🎬 KAZA Symbol Logo — solo el ícono/símbolo sin wordmark
class KazaSymbolLogo extends StatelessWidget {
  final double size;
  const KazaSymbolLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _kSvgSymbol,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// 🎬 KAZA Animated Logo — mantiene compatibilidad con GIF animado
/// Fallback al SVG Primary si useGif=false
class KazaAnimatedLogo extends StatelessWidget {
  final double width;
  final double? height;
  final BoxFit fit;
  final bool useGif;
  final bool dark;

  const KazaAnimatedLogo({
    super.key,
    this.width = 200,
    this.height,
    this.fit = BoxFit.contain,
    this.useGif = true,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useGif) {
      return Image.asset(
        'assets/images/kaza_logo.gif',
        width: width,
        height: height ?? width,
        fit: fit,
        errorBuilder: (_, __, ___) => SvgPicture.asset(
          dark ? _kSvgNegative : _kSvgPrimary,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }
    return SvgPicture.asset(
      dark ? _kSvgNegative : _kSvgPrimary,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

/// Widget de texto fallback cuando el SVG no carga
class _FallbackLogo extends StatelessWidget {
  final bool dark;
  const _FallbackLogo({this.dark = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
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
              color: dark ? Colors.white : KazaTheme.azulKaza,
            ),
          ),
        ],
      ),
    );
  }
}
