import 'package:flutter/material.dart';

class EllipseIcon extends StatelessWidget {
  const EllipseIcon({
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
      painter: _EllipseIconPainter(color),
    );
  }
}

class _EllipseIconPainter extends CustomPainter {
  const _EllipseIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.25,
        size.width * 0.7,
        size.height * 0.5,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EllipseIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
