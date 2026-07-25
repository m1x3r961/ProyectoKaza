import 'package:flutter/material.dart';

/// 🎨 KAZA BRAND IDENTITY SYSTEM v1.0 (Manual de Marca Oficial)
/// Paleta de colores oficial:
/// - Azul Kaza: #0F1F2E
/// - Coral Kaza: #FF5A3C
/// - Gris Claro: #F2F4F7
/// - Gris Medio: #A3A9B2
/// - Verde Entorno: #27AE60
class KazaTheme {
  // 1. PALETA DE COLORES OFICIAL DE MARCA
  static const Color azulKaza = Color(0xFF0F1F2E);       // #0F1F2E Azul Kaza (Fondo Primario / Dark Slate)
  static const Color coralKaza = Color(0xFFFF5A3C);      // #FF5A3C Coral Kaza (Accent Primario / Botón Publicar / Pines)
  static const Color grisClaro = Color(0xFFF2F4F7);       // #F2F4F7 Gris Claro (Superficie Cards / Chips)
  static const Color grisMedio = Color(0xFFA3A9B2);       // #A3A9B2 Gris Medio (Texto Secundario / Bordes)
  static const Color verdeEntorno = Color(0xFF27AE60);    // #27AE60 Verde Entorno (Kaza Score / Verificado)

  // 2. BACKWARD COMPATIBILITY TOKENS
  static const Color darkBackground = azulKaza;
  static const Color cardSurface = Color(0xFF162330);
  static const Color glassBorder = Color(0x22FFFFFF);

  static const Color primaryCoral = coralKaza;
  static const Color primaryCoralLight = Color(0xFFFF7A63);
  static const Color primaryCoralDark = Color(0xFFE04326);

  static const Color primaryTeal = coralKaza;
  static const Color primaryTealLight = primaryCoralLight;

  static const Color accentGold = Color(0xFFF6BD7B);
  static const Color accentGoldBright = Color(0xFFF8C88B);

  static const Color trustBlue = Color(0xFF2563EB);
  static const Color verifiedGreen = verdeEntorno;

  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = grisMedio;
  static const Color textMuted = grisMedio;

  static const Color statusAvailable = verdeEntorno;
  static const Color statusReserved = Color(0xFFF59E0B);
  static const Color statusClosed = Color(0xFFEF4444);
  static const Color statusPaused = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: azulKaza,
      colorScheme: const ColorScheme.dark(
        surface: cardSurface,
        primary: coralKaza,
        secondary: verdeEntorno,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: azulKaza,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardSurface,
        selectedItemColor: coralKaza,
        unselectedItemColor: grisMedio,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardSurface,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        secondarySelectedColor: coralKaza,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder),
        ),
      ),
    );
  }
}
