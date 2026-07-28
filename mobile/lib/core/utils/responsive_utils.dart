import 'package:flutter/material.dart';

/// 📐 KAZA RESPONSIVE UTILS
/// Helper centralizado para adaptar layouts a cualquier tamaño de pantalla.
/// Breakpoints:
///   • Phone   : width < 600
///   • Tablet  : width >= 600
class KazaResponsive {
  KazaResponsive._();

  // ── Breakpoints ────────────────────────────────────────────────────────────
  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  // ── Screen dimensions ──────────────────────────────────────────────────────
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // ── Safe area ──────────────────────────────────────────────────────────────
  static EdgeInsets safePadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  static double bottomSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  static double topSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  // ── Adaptive horizontal padding ────────────────────────────────────────────
  /// Padding horizontal estándar según tamaño de pantalla.
  static double horizontalPadding(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 12.0;
    if (w < 600) return 16.0;
    return 24.0;
  }

  /// EdgeInsets horizontal adaptativo.
  static EdgeInsets horizontalInsets(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: horizontalPadding(context));

  // ── Adaptive font sizes ────────────────────────────────────────────────────
  static double titleFontSize(BuildContext context) =>
      isTablet(context) ? 22.0 : 18.0;

  static double bodyFontSize(BuildContext context) =>
      isTablet(context) ? 14.0 : 13.0;

  // ── Adaptive grid cross-axis count ────────────────────────────────────────
  /// Retorna cuántas columnas usar en un GridView según el ancho.
  static int gridCrossAxisCount(BuildContext context, {int phone = 2, int tablet = 3}) =>
      isTablet(context) ? tablet : phone;

  // ── Bottom nav height (sin safe area) ─────────────────────────────────────
  static double bottomNavHeight(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 60.0;
    if (w < 600) return 68.0;
    return 72.0;
  }

  // ── Property card height en mapa ──────────────────────────────────────────
  static double mapPropertyCardHeight(BuildContext context) =>
      isTablet(context) ? 130.0 : 118.0;

  // ── Gallery/hero image height ─────────────────────────────────────────────
  static double galleryHeight(BuildContext context) {
    final h = screenHeight(context);
    if (h < 600) return 180.0;          // Pantallas muy pequeñas
    if (h < 800) return 220.0;          // iPhone SE, pequeños
    if (isTablet(context)) return 320.0; // Tablets
    return (h * 0.28).clamp(220.0, 300.0); // Phones normales
  }
}
