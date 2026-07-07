import 'package:flutter/material.dart';

class LineIcon extends StatelessWidget {
  const LineIcon({
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
      painter: _LineIconPainter(color),
    );
  }
}

class _LineIconPainter extends CustomPainter {
  const _LineIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LineIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
