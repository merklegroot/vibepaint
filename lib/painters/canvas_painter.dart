import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/stroke.dart' show Stroke, StrokeShape;

class CanvasPainter extends CustomPainter {
  CanvasPainter({
    required this.layers,
    this.currentStroke,
    this.backgroundImage,
  });

  final List<PaintLayer> layers;
  final Stroke? currentStroke;
  final ui.Image? backgroundImage;

  static void paintCanvas({
    required Canvas canvas,
    required Size size,
    required List<PaintLayer> layers,
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

    for (final layer in layers) {
      if (!layer.visible) {
        continue;
      }

      for (final stroke in layer.history.strokes) {
        _paintStroke(canvas, stroke);
      }
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
          final rect = Rect.fromPoints(stroke.points[0], stroke.points[1]);
          _paintBoundedShape(
            canvas: canvas,
            draw: (paint) => canvas.drawRect(rect, paint),
            fill: fill,
            line: line,
            style: stroke.style,
          );
        }
        return;
      case StrokeShape.ellipse:
        if (stroke.points.length >= 2) {
          final rect = Rect.fromPoints(stroke.points[0], stroke.points[1]);
          _paintBoundedShape(
            canvas: canvas,
            draw: (paint) => canvas.drawOval(rect, paint),
            fill: fill,
            line: line,
            style: stroke.style,
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

  static void _paintBoundedShape({
    required Canvas canvas,
    required void Function(Paint paint) draw,
    required Paint fill,
    required Paint line,
    required ShapeStyle style,
  }) {
    if (style.drawsFill) {
      draw(fill);
    }
    if (style.drawsOutline) {
      draw(line);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintCanvas(
      canvas: canvas,
      size: size,
      layers: layers,
      currentStroke: currentStroke,
      backgroundImage: backgroundImage,
    );
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    if (oldDelegate.backgroundImage != backgroundImage) {
      return true;
    }

    if (oldDelegate.layers.length != layers.length) {
      return true;
    }

    for (var i = 0; i < layers.length; i++) {
      final oldLayer = oldDelegate.layers[i];
      final newLayer = layers[i];
      if (oldLayer.visible != newLayer.visible) {
        return true;
      }
      if (oldLayer.history.strokes.length != newLayer.history.strokes.length) {
        return true;
      }
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
