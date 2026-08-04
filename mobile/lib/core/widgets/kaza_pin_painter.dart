import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 📍 PIN PAINTER CANÓNICO DE KAZA (Sin fondo blanco, vector degradado)
/// Soporta badge numérico de cantidad de propiedades (diseño WM-01 v0.2)
class KazaPinPainter extends CustomPainter {
  final IconData icon;
  final bool isSelected;
  /// Número de propiedades a mostrar en el badge. Si es <= 1, no se muestra badge.
  final int propertyCount;

  KazaPinPainter({
    required this.icon,
    this.isSelected = false,
    this.propertyCount = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double radius = width / 2;

    final Path pinPath = Path();
    pinPath.moveTo(radius, height);
    pinPath.cubicTo(
      width, height * 0.55,
      width, radius * 0.8,
      width, radius,
    );
    pinPath.arcTo(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius),
      0,
      -math.pi,
      false,
    );
    pinPath.cubicTo(
      0, radius * 0.8,
      0, height * 0.55,
      radius, height,
    );
    pinPath.close();

    // 1. Soft Shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(pinPath.shift(const Offset(0, 3)), shadowPaint);

    // 2. Kaza Fill
    final Paint fillPaint = Paint()..color = isSelected ? const Color(0xFFFF5A3C) : const Color(0xFF0F1F2E);
    canvas.drawPath(pinPath, fillPaint);

    // 3. Crisp White Border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;
    canvas.drawPath(pinPath, borderPaint);

    // 4. Category Icon in White
    final TextSpan span = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: radius * 1.1,
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

    // 6. Property Count Badge (top-right corner) — sólo si hay más de 1 propiedad
    if (propertyCount > 1) {
      _drawCountBadge(canvas, width, propertyCount);
    }
  }

  void _drawCountBadge(Canvas canvas, double pinWidth, int count) {
    final String label = count > 99 ? '99+' : count.toString();
    final double badgeRadius = pinWidth * 0.28;
    // Posición: esquina superior derecha del pin
    final Offset badgeCenter = Offset(pinWidth - badgeRadius * 0.4, badgeRadius * 0.4);

    // Sombra del badge
    canvas.drawCircle(
      badgeCenter + const Offset(0, 1.5),
      badgeRadius,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Fondo blanco del badge
    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()..color = Colors.white,
    );

    // Borde del badge con color coral
    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()
        ..color = const Color(0xFFFF5A3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Número dentro del badge
    final TextPainter badgeTp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: badgeRadius * (count > 9 ? 0.9 : 1.15),
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0F1F2E), // Azul Kaza
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    badgeTp.layout();
    badgeTp.paint(
      canvas,
      Offset(
        badgeCenter.dx - badgeTp.width / 2,
        badgeCenter.dy - badgeTp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant KazaPinPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected ||
      oldDelegate.icon != icon ||
      oldDelegate.propertyCount != propertyCount;
}
