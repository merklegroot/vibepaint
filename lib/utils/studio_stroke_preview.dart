import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/studio_brush_renderer.dart';

/// Incrementally rasterizes an in-progress studio brush stroke so live
/// drawing does not replay every stamp on each repaint.
class StudioStrokePreview {
  ui.Image? image;
  int rasterizedPointCount = 0;

  void clear() {
    image?.dispose();
    image = null;
    rasterizedPointCount = 0;
  }

  void dispose() => clear();

  void appendPoints(Stroke stroke, Size documentSize) {
    final start = rasterizedPointCount;
    final end = stroke.points.length;
    if (!stroke.isStudioBrush || start >= end) {
      return;
    }

    final width = documentSize.width.ceil();
    final height = documentSize.height.ceil();
    if (width <= 0 || height <= 0) {
      return;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    final previous = image;
    if (previous != null) {
      canvas.drawImage(previous, Offset.zero, Paint());
      previous.dispose();
      image = null;
    }

    paintStudioBrushStrokeRange(
      canvas,
      stroke,
      startIndex: start,
      endIndex: end,
    );

    final picture = recorder.endRecording();
    image = picture.toImageSync(width, height);
    picture.dispose();
    rasterizedPointCount = end;
  }
}
