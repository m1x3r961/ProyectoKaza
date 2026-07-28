import 'package:flutter/material.dart';

/// 🎨 KAZA BRAND IDENTITY SYSTEM v1.0 (Manual de Marca Oficial - Light Mode)
/// Paleta de colores oficial:
/// - Azul Kaza: #0F1F2E (Texto primario / Botones de acción)
/// - Coral Kaza: #FF5A3C (Accent primario / Botón FAB + / Precios)
/// - Gris Claro: #F2F4F7 (Fondo secundario / Chips desleccionados)
/// - Gris Medio: #A3A9B2 (Texto secundario / Bordes)
/// - Verde Entorno: #27AE60 (Kaza Score / Verificado)
class KazaTheme {
  // 1. PALETA DE COLORES OFICIAL DE MARCA
  static const Color azulKaza = Color(0xFF101F31);       // #101F31 Azul Kaza
  static const Color coralKaza = Color(0xFFF45B45);      // #F45B45 Coral Kaza
  static const Color grisClaro = Color(0xFFF2F4F7);       // #F2F4F7 Gris Claro
  static const Color grisMedio = Color(0xFFA3A9B2);       // #A3A9B2 Gris Medio
  static const Color verdeEntorno = Color(0xFF27AE60);    // #27AE60 Verde Entorno

  // 2. SUPERFICIES LIGHT MODE (Fiel al Mockup)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;

  // Backward compatibility tokens
  static const Color darkBackground = lightBackground;

  static const Color primaryCoral = coralKaza;
  static const Color primaryCoralLight = coralKaza;
  static const Color primaryCoralDark = Color(0xFFE04326);

  static const Color primaryTeal = coralKaza;
  static const Color primaryTealLight = coralKaza;

  static const Color accentGold = Color(0xFFF6BD7B);
  static const Color accentGoldBright = Color(0xFFF8C88B);

  static const Color trustBlue = Color(0xFF2563EB);
  static const Color verifiedGreen = verdeEntorno;

  static const Color textPrimary = azulKaza;
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = grisMedio;

  static const Color statusAvailable = verdeEntorno;
  static const Color statusReserved = Color(0xFFF59E0B);
  static const Color statusClosed = Color(0xFFEF4444);
  static const Color statusPaused = Color(0xFF6B7280);

  static const Color glassBorder = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        surface: cardSurface,
        primary: coralKaza,
        secondary: verdeEntorno,
        onSurface: azulKaza,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: azulKaza),
        titleTextStyle: TextStyle(
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
        labelStyle: const TextStyle(color: azulKaza, fontSize: 13, fontWeight: FontWeight.w600),
        secondarySelectedColor: azulKaza,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
