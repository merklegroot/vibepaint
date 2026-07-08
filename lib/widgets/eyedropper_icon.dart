import 'package:flutter/material.dart';

class EyedropperIcon extends StatelessWidget {
  const EyedropperIcon({
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
      painter: _EyedropperIconPainter(color),
    );
  }
}

class _EyedropperIconPainter extends CustomPainter {
  const _EyedropperIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tip = Offset(w * 0.86, h * 0.1);
    final rightJoint = Offset(w * 0.58, h * 0.4);
    final leftJoint = Offset(w * 0.46, h * 0.34);

    final shell = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(rightJoint.dx, rightJoint.dy)
      ..cubicTo(
        w * 0.56,
        h * 0.54,
        w * 0.42,
        h * 0.76,
        w * 0.24,
        h * 0.82,
      )
      ..cubicTo(
        w * 0.08,
        h * 0.88,
        w * 0.04,
        h * 0.68,
        w * 0.14,
        h * 0.54,
      )
      ..lineTo(leftJoint.dx, leftJoint.dy)
      ..lineTo(w * 0.7, h * 0.15)
      ..close();

    canvas.drawPath(shell, stroke);

    canvas.drawLine(
      Offset(w * 0.22, h * 0.72),
      Offset(w * 0.78, h * 0.16),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.24, h * 0.66),
        width: w * 0.2,
        height: h * 0.14,
      ),
      2.4,
      1.1,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      tip,
      1.45,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _EyedropperIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
