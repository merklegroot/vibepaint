import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vibepaint/models/stroke.dart' show Stroke, StrokeShape;

class CanvasPainter extends CustomPainter {
  CanvasPainter({
    required this.strokes,
    this.currentStroke,
    this.backgroundImage,
  });

  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final ui.Image? backgroundImage;

  static void paintCanvas({
    required Canvas canvas,
    required Size size,
    required List<Stroke> strokes,
    Stroke? currentStroke,
    ui.Image? backgroundImage,
  }) {
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage,
        Rect.fromLTWH(
          0,
          0,
          backgroundImage.width.toDouble(),
          backgroundImage.height.toDouble(),
        ),
        Offset.zero & size,
        Paint(),
      );
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    }

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke);
    }
  }

  static void _paintStroke(Canvas canvas, Stroke stroke) {
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

    switch (stroke.shape) {
      case StrokeShape.line:
        if (stroke.points.length >= 2) {
          canvas.drawLine(stroke.points[0], stroke.points[1], line);
        }
        return;
      case StrokeShape.rectangle:
        if (stroke.points.length >= 2) {
          canvas.drawRect(
            Rect.fromPoints(stroke.points[0], stroke.points[1]),
            line,
          );
        }
        return;
      case StrokeShape.freehand:
        break;
    }

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.brushSize / 2, fill);
      return;
    }

    for (var i = 0; i < stroke.points.length - 1; i++) {
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], line);
    }

    canvas.drawCircle(stroke.points.last, stroke.brushSize / 2, fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintCanvas(
      canvas: canvas,
      size: size,
      strokes: strokes,
      currentStroke: currentStroke,
      backgroundImage: backgroundImage,
    );
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    if (oldDelegate.backgroundImage != backgroundImage) {
      return true;
    }

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
