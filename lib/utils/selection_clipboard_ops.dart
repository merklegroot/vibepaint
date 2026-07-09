import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/layer_stack.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/painters/canvas_painter.dart';
import 'package:vibepaint/utils/canvas_clipboard.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

Future<CanvasClipboardData?> copySelectionToClipboard({
  required Size documentSize,
  required LayerStack layerStack,
  required CanvasSelection selection,
  required bool merged,
}) async {
  if (documentSize == Size.zero || selection.isEmpty) {
    return null;
  }

  final pngBytes = await _renderSelectionPng(
    documentSize: documentSize,
    layerStack: layerStack,
    selection: selection,
    merged: merged,
  );
  if (pngBytes == null) {
    return null;
  }

  final data = CanvasClipboardData(
    pngBytes: pngBytes,
    size: selection.bounds.size,
    origin: selection.bounds.topLeft,
  );
  CanvasClipboard.set(data);
  return data;
}

Future<Stroke?> pasteClipboardAsStroke({
  required Size documentSize,
  required Offset pasteOrigin,
}) async {
  final data = CanvasClipboard.data;
  if (data == null || documentSize == Size.zero) {
    return null;
  }

  final image = await decodeImageBytes(data.pngBytes);
  try {
    return Stroke(
      color: const Color(0x00000000),
      brushSize: 0,
      shape: StrokeShape.raster,
      points: [pasteOrigin],
      rasterImage: image,
      rasterBounds: Rect.fromLTWH(
        pasteOrigin.dx,
        pasteOrigin.dy,
        data.size.width,
        data.size.height,
      ),
    );
  } catch (_) {
    image.dispose();
    rethrow;
  }
}

Offset nextPasteOrigin(CanvasClipboardData data) {
  return data.origin + const Offset(10, 10);
}

Future<Stroke?> buildSelectionFillStroke({
  required Size documentSize,
  required CanvasSelection selection,
  required Color fillColor,
}) async {
  if (documentSize == Size.zero || selection.isEmpty) {
    return null;
  }

  final bounds = selection.bounds;
  if (bounds.isEmpty) {
    return null;
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.save();
  canvas.translate(-bounds.left, -bounds.top);
  canvas.clipPath(selection.path);
  canvas.drawRect(
    Offset.zero & documentSize,
    Paint()..color = fillColor,
  );
  canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    bounds.width.ceil().clamp(1, documentSize.width.ceil()),
    bounds.height.ceil().clamp(1, documentSize.height.ceil()),
  );
  picture.dispose();

  return Stroke(
    color: fillColor,
    brushSize: 0,
    shape: StrokeShape.raster,
    points: [bounds.topLeft],
    rasterImage: image,
    rasterBounds: bounds,
  );
}

Future<Uint8List?> _renderSelectionPng({
  required Size documentSize,
  required LayerStack layerStack,
  required CanvasSelection selection,
  required bool merged,
}) async {
  final bounds = selection.bounds;
  if (bounds.isEmpty) {
    return null;
  }

  final width = bounds.width.ceil().clamp(1, documentSize.width.ceil());
  final height = bounds.height.ceil().clamp(1, documentSize.height.ceil());
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.save();
  canvas.translate(-bounds.left, -bounds.top);
  canvas.clipPath(selection.path);

  if (merged) {
    CanvasPainter.paintCanvas(
      canvas: canvas,
      size: documentSize,
      layers: layerStack.layers,
      activeLayerIndex: layerStack.activeIndex,
      backgroundImage: layerStack.backgroundImage,
      backgroundColor: layerStack.backgroundColor,
    );
  } else {
    _paintActiveLayerContent(
      canvas: canvas,
      bounds: Offset.zero & documentSize,
      layer: layerStack.activeLayer,
    );
  }

  canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();

  try {
    final raster = await uiImageToRasterImage(image);
    return Uint8List.fromList(img.encodePng(raster));
  } finally {
    image.dispose();
  }
}

void _paintActiveLayerContent({
  required Canvas canvas,
  required Rect bounds,
  required PaintLayer layer,
}) {
  if (!layer.visible || layer.opacity <= 0) {
    return;
  }

  canvas.saveLayer(bounds, Paint());
  for (final stroke in layer.history.strokes) {
    CanvasPainter.paintStroke(canvas, stroke, canvasBounds: bounds);
  }
  canvas.restore();
}
