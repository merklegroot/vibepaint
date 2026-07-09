import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/layer_stack.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

extension LayerStackAdjustments on LayerStack {
  bool get activeLayerHasAdjustableContent =>
      activeLayer.visible && activeHistory.strokes.isNotEmpty;

  Future<img.Image?> captureActiveLayerRaster(Size size) async {
    if (!activeLayerHasAdjustableContent) {
      return null;
    }

    final rgba = await renderStrokesRgbaBytes(
      size: size,
      strokes: activeHistory.strokes,
    );
    if (rgba == null) {
      return null;
    }

    final width = size.width.ceil();
    final height = size.height.ceil();
    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  }

  Future<void> replaceActiveLayerWithRaster({
    required Size size,
    required img.Image raster,
  }) async {
    final uiImage = await rasterImageToUiImage(raster);
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    activeHistory.replaceStrokes([
      Stroke(
        color: const Color(0x00000000),
        brushSize: 0,
        shape: StrokeShape.raster,
        points: [bounds.topLeft],
        rasterImage: uiImage,
        rasterBounds: bounds,
      ),
    ]);
  }

  Future<void> applyActiveLayerAdjustment(
    Size size,
    img.Image Function(img.Image source) transform,
  ) async {
    final source = await captureActiveLayerRaster(size);
    if (source == null) {
      return;
    }

    await replaceActiveLayerWithRaster(
      size: size,
      raster: transform(source),
    );
  }

  void restoreActiveLayerStrokes(List<Stroke> strokes) {
    activeHistory.replaceStrokes(strokes);
  }

  List<Stroke> backupActiveLayerStrokes() {
    return [
      for (final stroke in activeHistory.strokes) stroke.copyWith(),
    ];
  }
}

Future<img.Image?> rasterFromRgba(Uint8List rgba, Size size) async {
  final width = size.width.ceil();
  final height = size.height.ceil();
  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}
