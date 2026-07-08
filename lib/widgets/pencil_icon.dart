import 'package:flutter/material.dart';

class PencilIcon extends StatelessWidget {
  const PencilIcon({
    super.key,
    this.size = 20,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PencilIconPainter(color),
    );
  }
}

class _PencilIconPainter extends CustomPainter {
  const _PencilIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    final shaft = Path()
      ..moveTo(w * 0.18, h * 0.82)
      ..lineTo(w * 0.34, h * 0.66)
      ..lineTo(w * 0.78, h * 0.2)
      ..lineTo(w * 0.86, h * 0.12)
      ..lineTo(w * 0.8, h * 0.08)
      ..lineTo(w * 0.3, h * 0.58)
      ..lineTo(w * 0.12, h * 0.76)
      ..close();

    canvas.drawPath(shaft, body);
    canvas.drawPath(shaft, outline);

    final tip = Path()
      ..moveTo(w * 0.78, h * 0.2)
      ..lineTo(w * 0.86, h * 0.12)
      ..lineTo(w * 0.8, h * 0.08)
      ..close();

    canvas.drawPath(
      tip,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill,
    );

    canvas.drawLine(
      Offset(w * 0.24, h * 0.76),
      Offset(w * 0.42, h * 0.58),
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PencilIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
