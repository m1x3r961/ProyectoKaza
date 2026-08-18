import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 📍 KAZA MAP VISUAL GRAMMAR — Pin Painter v2.0
/// Implements the complete visual grammar from the KAZA Master Design:
///
///   ● Property (disponible) — Navy drop-pin with white icon
///   ● Property seleccionada — Coral drop-pin with white icon
///   ● Cluster (propiedades) — Navy circle with white count number
///   ● POI / Punto de interés — Small green dot
///   ● Contexto / Barrio — Small peach/salmon dot
///
enum KazaPinType {
  property,     // Navy drop-pin
  selected,     // Coral drop-pin
  cluster,      // Navy circle with number
  poi,          // Green dot
  context,      // Peach dot
}

class KazaPinPainter extends CustomPainter {
  final IconData icon;
  final bool isSelected;
  final int propertyCount;

  // Kaza brand colors
  static const Color _navyColor = Color(0xFF0F1F2E);
  static const Color _coralColor = Color(0xFFFF5A3C);

  KazaPinPainter({
    required this.icon,
    this.isSelected = false,
    this.propertyCount = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If cluster (propertyCount > 1), draw circle with number
    if (propertyCount > 1) {
      _drawClusterCircle(canvas, size);
      return;
    }

    // Otherwise, draw drop-pin
    _drawDropPin(canvas, size);
  }

  /// Draws a navy/coral drop-pin shape with icon
  void _drawDropPin(Canvas canvas, Size size) {
    final double radius = size.width / 2;

    final Path pinPath = Path();
    pinPath.moveTo(radius, size.height);
    pinPath.cubicTo(
      size.width, size.height * 0.55,
      size.width, radius * 0.8,
      size.width, radius,
    );
    pinPath.arcTo(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius),
      0,
      -math.pi,
      false,
    );
    pinPath.cubicTo(
      0, radius * 0.8,
      0, size.height * 0.55,
      radius, size.height,
    );
    pinPath.close();

    // 1. Soft shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(pinPath.shift(const Offset(0, 3)), shadowPaint);

    // 2. Fill — Navy default, Coral when selected
    final Paint fillPaint = Paint()
      ..color = isSelected ? _coralColor : _navyColor;
    canvas.drawPath(pinPath, fillPaint);

    // 3. White border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 2.0;
    canvas.drawPath(pinPath, borderPaint);

    // 4. White icon centered in the circle portion
    final TextSpan span = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: radius * 1.0,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );

    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(radius - tp.width / 2, (radius * 0.95) - tp.height / 2));
  }

  /// Draws a navy circle with white number for clusters
  void _drawClusterCircle(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = math.min(centerX, centerY);

    // 1. Shadow
    canvas.drawCircle(
      Offset(centerX, centerY + 2),
      radius,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 2. Navy fill
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()..color = _navyColor,
    );

    // 3. White border
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 4. White number
    final String label = propertyCount > 99 ? '99+' : propertyCount.toString();
    final double fontSize = propertyCount > 9 ? radius * 0.85 : radius * 1.0;

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(centerX - tp.width / 2, centerY - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant KazaPinPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected ||
      oldDelegate.icon != icon ||
      oldDelegate.propertyCount != propertyCount;
}

/// 🟢 POI Pin Painter — Small colored dot for points of interest
class KazaPoiPinPainter extends CustomPainter {
  final Color color;
  final IconData? icon;

  static const Color poiGreen = Color(0xFF27AE60);
  static const Color contextPeach = Color(0xFFF6BD7B);

  KazaPoiPinPainter({
    this.color = poiGreen,
    this.icon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = math.min(centerX, centerY);

    // Shadow
    canvas.drawCircle(
      Offset(centerX, centerY + 1.5),
      radius,
      Paint()
        ..color = Colors.black12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Fill
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()..color = color,
    );

    // White border
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Icon if provided
    if (icon != null) {
      final TextSpan span = TextSpan(
        text: String.fromCharCode(icon!.codePoint),
        style: TextStyle(
          fontSize: radius * 0.9,
          fontFamily: icon!.fontFamily,
          package: icon!.fontPackage,
          color: Colors.white,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(centerX - tp.width / 2, centerY - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant KazaPoiPinPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.icon != icon;
}
