import 'package:flutter/material.dart';

class RectangleIcon extends StatelessWidget {
  const RectangleIcon({
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
      painter: _RectangleIconPainter(color),
    );
  }
}

class _RectangleIconPainter extends CustomPainter {
  const _RectangleIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.25,
        size.width * 0.6,
        size.height * 0.5,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RectangleIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
