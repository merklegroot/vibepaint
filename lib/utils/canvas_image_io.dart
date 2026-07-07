import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/painters/canvas_painter.dart';

Future<Uint8List> renderCanvasToPng({
  required Size size,
  required List<Stroke> strokes,
  ui.Image? backgroundImage,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  CanvasPainter.paintCanvas(
    canvas: canvas,
    size: size,
    strokes: strokes,
    backgroundImage: backgroundImage,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    size.width.ceil(),
    size.height.ceil(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  if (byteData == null) {
    throw StateError('Failed to encode PNG');
  }

  return byteData.buffer.asUint8List();
}

Future<ui.Image> decodePngBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
