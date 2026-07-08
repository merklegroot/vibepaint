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
    final w = size.width;
    final h = size.height;

    final handle = Offset(w * 0.78, h * 0.2);
    final path = Path()
      ..moveTo(handle.dx, handle.dy)
      ..lineTo(w * 0.7, h * 0.34)
      ..cubicTo(
        w * 0.62,
        h * 0.56,
        w * 0.42,
        h * 0.8,
        w * 0.2,
        h * 0.68,
      )
      ..cubicTo(
        w * 0.08,
        h * 0.5,
        w * 0.16,
        h * 0.28,
        w * 0.38,
        h * 0.24,
      )
      ..cubicTo(
        w * 0.52,
        h * 0.22,
        w * 0.62,
        h * 0.28,
        w * 0.66,
        h * 0.36,
      );

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tail = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.84, h * 0.1),
      handle,
      tail,
    );

    _drawDashedPath(canvas: canvas, path: path, paint: stroke);

    canvas.drawCircle(
      handle,
      1.75,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      handle,
      1.75,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75,
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
  bool shouldRepaint(covariant _LassoSelectIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
