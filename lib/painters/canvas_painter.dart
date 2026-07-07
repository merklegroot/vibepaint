import 'package:flutter/material.dart';
import 'package:vibepaint/models/stroke.dart';

class CanvasPainter extends CustomPainter {
  CanvasPainter({
    required this.strokes,
    this.currentStroke,
  });

  final List<Stroke> strokes;
  final Stroke? currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) {
      return;
    }

    final fill = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.brushSize / 2, fill);
      return;
    }

    for (var i = 0; i < stroke.points.length - 1; i++) {
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], line);
    }

    canvas.drawCircle(
      stroke.points.last,
      stroke.brushSize / 2,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    if (oldDelegate.strokes.length != strokes.length) {
      return true;
    }

    final oldCurrent = oldDelegate.currentStroke;
    final newCurrent = currentStroke;
    if (oldCurrent == null && newCurrent == null) {
      return false;
    }
    if (oldCurrent == null || newCurrent == null) {
      return true;
    }

    return oldCurrent.points.length != newCurrent.points.length;
  }
}
