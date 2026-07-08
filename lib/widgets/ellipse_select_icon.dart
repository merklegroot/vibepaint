import 'package:flutter/material.dart';

class EllipseSelectIcon extends StatelessWidget {
  const EllipseSelectIcon({
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
      painter: _EllipseSelectIconPainter(color),
    );
  }
}

class _EllipseSelectIconPainter extends CustomPainter {
  const _EllipseSelectIconPainter(this.color);

  final Color color;

  static const _dashLength = 2.5;
  static const _gapLength = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.22,
      size.width * 0.72,
      size.height * 0.56,
    );

    _drawDashedPath(
      canvas: canvas,
      path: Path()..addOval(rect),
      paint: paint,
    );
  }

  static void _drawDashedPath({
    required Canvas canvas,
    required Path path,
    required Paint paint,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EllipseSelectIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
