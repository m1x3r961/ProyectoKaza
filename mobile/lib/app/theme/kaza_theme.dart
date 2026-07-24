import 'package:flutter/material.dart';

/// Kaza Product Architecture Master v0.2 - Design System & Tokens
/// Premium Dark Mode with HSL Slate Navy background, Teal & Gold accents, 
/// glassmorphism cards and modern typography.
class KazaTheme {
  // Brand Palette - Derived from assets/images/logo.png
  static const Color darkBackground = Color(0xFF0B0F17); // Deep Slate
  static const Color cardSurface = Color(0xFF161C26); // Dark Navy Surface
  static const Color glassBorder = Color(0x22FFFFFF); // Glass Border

  // Primary Coral Red / Terracotta Palette (From Logo Location Pin)
  static const Color primaryCoral = Color(0xFFE05A47); // Kaza Coral Red
  static const Color primaryCoralLight = Color(0xFFEE7263); // Light Coral Highlight
  static const Color primaryCoralDark = Color(0xFFC84332);

  // Backward compatibility alias for primary color tokens
  static const Color primaryTeal = primaryCoral;
  static const Color primaryTealLight = primaryCoralLight;

  // Sunset Peach Gold (From Logo Roof)
  static const Color accentGold = Color(0xFFF6BD7B); // Kaza Peach Gold Accent
  static const Color accentGoldBright = Color(0xFFF8C88B);
  
  static const Color trustBlue = Color(0xFF2563EB); // Trust Badge Blue
  static const Color verifiedGreen = Color(0xFF10B981); // Verification Green

  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Status Colors
  static const Color statusAvailable = Color(0xFF10B981);
  static const Color statusReserved = Color(0xFFF59E0B);
  static const Color statusClosed = Color(0xFFEF4444);
  static const Color statusPaused = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: cardSurface,
        primary: primaryCoral,
        secondary: accentGold,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
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
        selectedItemColor: primaryCoralLight,
        unselectedItemColor: textMuted,
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
        secondarySelectedColor: primaryCoral,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder),
        ),
      ),
    );
  }
}
