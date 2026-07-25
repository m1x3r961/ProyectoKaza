import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 📍 PIN PAINTER CANÓNICO DE KAZA (Sin fondo blanco, vector degradado)
class KazaPinPainter extends CustomPainter {
  final IconData icon;
  final bool isSelected;

  KazaPinPainter({
    required this.icon,
    this.isSelected = false,
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

    // 2. Kaza Gradient Fill (Peach Gold to Coral Red)
    final Paint fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF6BD7B), // Peach Gold
          Color(0xFFE05A47), // Coral Red
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(pinPath, fillPaint);

    // 3. Crisp White Border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;
    canvas.drawPath(pinPath, borderPaint);

    // 4. Central Inner Circle
    final double innerRadius = radius * 0.52;
    final Paint innerCirclePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(radius, radius * 0.92), innerRadius, innerCirclePaint);

    // 5. Category Icon inside central circle
    final TextSpan span = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: innerRadius * 1.3,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: const Color(0xFFE05A47),
      ),
    );

    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(radius - tp.width / 2, (radius * 0.92) - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant KazaPinPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected || oldDelegate.icon != icon;
}
