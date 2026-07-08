import 'package:flutter/material.dart';

class LassoSelectIcon extends StatelessWidget {
  const LassoSelectIcon({
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
      painter: _LassoSelectIconPainter(color),
    );
  }
}

class _LassoSelectIconPainter extends CustomPainter {
  const _LassoSelectIconPainter(this.color);

  final Color color;

  static const _dashLength = 2.5;
  static const _gapLength = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.08,
        size.height * 0.58,
        size.width * 0.28,
        size.height * 0.74,
      )
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.84,
        size.width * 0.78,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.42,
        size.width * 0.68,
        size.height * 0.24,
      )
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.12,
        size.width * 0.2,
        size.height * 0.34,
      );

    _drawDashedPath(canvas: canvas, path: path, paint: paint);
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
  bool shouldRepaint(covariant _LassoSelectIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
