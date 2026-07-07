import 'package:flutter/material.dart';

class EraserIcon extends StatelessWidget {
  const EraserIcon({
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
      painter: _EraserIconPainter(color),
    );
  }
}

class _EraserIconPainter extends CustomPainter {
  const _EraserIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.35);
    canvas.translate(-size.width / 2, -size.height / 2);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.28, size.width * 0.7, size.height * 0.5),
      Radius.circular(size.width * 0.08),
    );

    canvas.drawRRect(body, Paint()..color = color);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(size.width * 0.15, size.height * 0.28, size.width * 0.7, size.height * 0.2),
        topLeft: Radius.circular(size.width * 0.08),
        topRight: Radius.circular(size.width * 0.08),
      ),
      Paint()..color = color.withValues(alpha: 0.45),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EraserIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
