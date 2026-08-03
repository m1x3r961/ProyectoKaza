import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 KAZA BRAND IDENTITY SYSTEM v2.0 — Design System Maestro B26
/// ─────────────────────────────────────────────────────────────────
/// Paleta principal:
///   Kaza Navy  #0F1F2E  Azul marca / texto primario / botones
///   Kaza Coral #FF5A3C  Accent primario / precios / FAB
///
/// Paleta neutral (N000–N700):
///   N000 #F2F5EE · N100 #D2D3CF · N300 #949896
///   N700 #464748 · N500 #0B1224
///
/// Colores semánticos DS B26:
///   Éxito #2CA754 · Advertencia #F5A623 · Error #E53935
///   Información #1E88E5 · Nuevo #7C3AED
class KazaTheme {
  // ── 1. PALETA DE COLORES PRINCIPAL ──────────────────────────────
  static const Color azulKaza   = Color(0xFF0F1F2E); // #0F1F2E Navy
  static const Color coralKaza  = Color(0xFFFF5A3C); // #FF5A3C Coral
  static const Color grisClaro  = Color(0xFFF2F4F7); // #F2F4F7 Gris Claro (bg)
  static const Color grisMedio  = Color(0xFFA3A9B2); // #A3A9B2 Gris Medio
  static const Color verdeEntorno = Color(0xFF27AE60); // #27AE60 Verde

  // ── 2. ESCALA NEUTRAL DS MAESTRO B26 ────────────────────────────
  static const Color n500  = Color(0xFF0B1224); // Texto máximo oscuro
  static const Color n700  = Color(0xFF464748); // Gris oscuro
  static const Color n300  = Color(0xFF949896); // Gris medio DS
  static const Color n100  = Color(0xFFD2D3CF); // Gris claro DS
  static const Color n000  = Color(0xFFF2F5EE); // Fondo off-white DS
  static const Color white = Color(0xFFFFFFFF);

  // ── 3. COLORES SEMÁNTICOS DS B26 ────────────────────────────────
  static const Color semanticSuccess     = Color(0xFF2CA754); // Éxito
  static const Color semanticWarning     = Color(0xFFF5A623); // Advertencia
  static const Color semanticError       = Color(0xFFE53935); // Error
  static const Color semanticInfo        = Color(0xFF1E88E5); // Información
  static const Color semanticNew         = Color(0xFF7C3AED); // Nuevo

  // ── 4. SUPERFICIES LIGHT MODE ───────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color cardSurface     = Colors.white;

  // ── 5. ALIAS BACKWARD COMPATIBILITY ────────────────────────────
  static const Color darkBackground     = lightBackground;
  static const Color primaryCoral       = coralKaza;
  static const Color primaryCoralLight  = coralKaza;
  static const Color primaryCoralDark   = Color(0xFFE04326);
  static const Color primaryTeal        = coralKaza;
  static const Color primaryTealLight   = coralKaza;
  static const Color accentGold         = Color(0xFFF6BD7B);
  static const Color accentGoldBright   = Color(0xFFF8C88B);
  static const Color trustBlue          = Color(0xFF2563EB);
  static const Color verifiedGreen      = verdeEntorno;
  static const Color textPrimary        = azulKaza;
  static const Color textSecondary      = Color(0xFF475569);
  static const Color textMuted          = grisMedio;
  static const Color statusAvailable    = verdeEntorno;
  static const Color statusReserved     = Color(0xFFF59E0B);
  static const Color statusClosed       = Color(0xFFEF4444);
  static const Color statusPaused       = Color(0xFF6B7280);
  static const Color glassBorder        = Color(0xFFE2E8F0);

  // ── 6. ESCALA TIPOGRÁFICA MANROPE — DS MAESTRO B26 ──────────────
  /// Display 1 — 70px / 68 leading / ExtraBold 800
  static TextStyle display1({Color color = const Color(0xFF0F1F2E)}) =>
      GoogleFonts.manrope(fontSize: 70, fontWeight: FontWeight.w800, height: 68/70, color: color);

  /// Display 2 — 56px / 64 leading / Bold 700
  static TextStyle display2({Color color = const Color(0xFF0F1F2E)}) =>
      GoogleFonts.manrope(fontSize: 56, fontWeight: FontWeight.w700, height: 64/56, color: color);

  /// H1 — Título principal — 46px / 52 / Bold 700
  static TextStyle heading1({Color color = const Color(0xFF0F1F2E)}) =>
      GoogleFonts.manrope(fontSize: 46, fontWeight: FontWeight.w700, height: 52/46, color: color);

  /// H2 — Título de sección — 36px / 44 / Bold 700
  static TextStyle heading2({Color color = const Color(0xFF0F1F2E)}) =>
      GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w700, height: 44/36, color: color);

  /// H3 — Encabezado — 28px / 36 / SemiBold 600
  static TextStyle heading3({Color color = const Color(0xFF0F1F2E)}) =>
      GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w600, height: 36/28, color: color);

  /// Title Large — 24px / 32 / SemiBold 600
  static TextStyle titleLarge({Color color = const Color(0xFF0F1F2E)}) =>
      GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w600, height: 32/24, color: color);

  /// Title — Componentes — 20px / 28 / SemiBold 600
  static TextStyle titleStyle({Color color = const Color(0xFF0F1F2E)}) =>
      GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, height: 28/20, color: color);

  /// Body Large — Lectura general — 18px / 28 / Regular 400
  static TextStyle bodyLarge({Color color = const Color(0xFF475569)}) =>
      GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w400, height: 28/18, color: color);

  /// Body — Texto secundario — 16px / 24 / Regular 400
  static TextStyle bodyStyle({Color color = const Color(0xFF475569)}) =>
      GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w400, height: 24/16, color: color);

  /// Caption — Etiquetas, tags — 14px / 20 / Regular 400
  static TextStyle caption({Color color = const Color(0xFFA3A9B2)}) =>
      GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w400, height: 20/14, color: color);

  /// Label — Micro texto — 12px / 16 / SemiBold 600
  static TextStyle label({Color color = const Color(0xFF0F1F2E)}) =>
      GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, height: 16/12, color: color);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      // ── Manrope como fuente base (DS Maestro B26) ──────────────────
      textTheme: GoogleFonts.manropeTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(fontSize: 70, fontWeight: FontWeight.w800, color: azulKaza),
          displayMedium: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: azulKaza),
          headlineLarge: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: azulKaza),
          headlineMedium:TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: azulKaza),
          headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: azulKaza),
          titleLarge:    TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: azulKaza),
          titleMedium:   TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: azulKaza),
          bodyLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xFF475569)),
          bodyMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF475569)),
          bodySmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFA3A9B2)),
          labelSmall:    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: azulKaza),
        ),
      ),
      colorScheme: const ColorScheme.light(
        surface: cardSurface,
        primary: coralKaza,
        secondary: verdeEntorno,
        onSurface: azulKaza,
        error: semanticError,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: azulKaza),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: azulKaza,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: coralKaza,
        unselectedItemColor: grisMedio,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grisClaro,
        labelStyle: GoogleFonts.manrope(color: azulKaza, fontSize: 13, fontWeight: FontWeight.w600),
        secondarySelectedColor: azulKaza,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: n000,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: n100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: n100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: azulKaza, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: semanticError),
        ),
        hintStyle: const TextStyle(color: n300, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coralKaza,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: azulKaza,
          side: const BorderSide(color: azulKaza),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
