import 'package:flutter/material.dart';

/// Pivot, guide circle, and drag handle shown during free rotate mode.
class RotateOverlayPainter extends CustomPainter {
  RotateOverlayPainter({
    required this.center,
    this.dragPosition,
    this.startAngle,
    this.previewAngle = 0,
  });

  final Offset center;
  final Offset? dragPosition;
  final double? startAngle;
  final double previewAngle;

  static const _guideRadius = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, _guideRadius, guidePaint);
    canvas.drawCircle(
      center,
      _guideRadius,
      guidePaint..color = Colors.black.withValues(alpha: 0.35),
    );

    if (startAngle != null) {
      final startEnd = center + Offset.fromDirection(startAngle!, _guideRadius);
      _drawGuideLine(canvas, center, startEnd, const Color(0x99FFFFFF));
    }

    if (dragPosition != null) {
      _drawGuideLine(canvas, center, dragPosition!, const Color(0xFFDCDCDC));

      if (previewAngle.abs() > 0.01) {
        final arcRect = Rect.fromCircle(center: center, radius: _guideRadius);
        final arcPaint = Paint()
          ..color = const Color(0xCCFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawArc(
          arcRect,
          startAngle ?? 0,
          previewAngle,
          false,
          arcPaint,
        );
      }
    }

    const pivotRadius = 5.0;
    canvas.drawCircle(
      center,
      pivotRadius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      pivotRadius,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    const crosshair = 10.0;
    final crosshairPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    canvas.drawLine(
      center - const Offset(crosshair, 0),
      center + const Offset(crosshair, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      center - const Offset(0, crosshair),
      center + const Offset(0, crosshair),
      crosshairPaint,
    );
  }

  static void _drawGuideLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      end,
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant RotateOverlayPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.dragPosition != dragPosition ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.previewAngle != previewAngle;
  }
}
