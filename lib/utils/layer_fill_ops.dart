import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/theme/color_wells.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';
import 'package:vibepaint/utils/flood_fill.dart';

Future<img.Image?> _renderStrokesRaster({
  required Size size,
  required List<Stroke> strokes,
}) async {
  final rgba = await renderStrokesRgbaBytes(size: size, strokes: strokes);
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

img.Image _cloneRaster(img.Image source) {
  final bytes = Uint8List.fromList(
    source.getBytes(order: img.ChannelOrder.rgba),
  );
  return img.Image.fromBytes(
    width: source.width,
    height: source.height,
    bytes: bytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}

img.ColorRgba8 _toImageColor(Color color) {
  return img.ColorRgba8(
    (color.r * 255).round().clamp(0, 255),
    (color.g * 255).round().clamp(0, 255),
    (color.b * 255).round().clamp(0, 255),
    (color.a * 255).round().clamp(0, 255),
  );
}

Future<Stroke?> buildFillStroke({
  required Size size,
  required List<Stroke> strokes,
  required Offset position,
  required Color fillColor,
  required double tolerance,
}) async {
  final image = await _renderStrokesRaster(size: size, strokes: strokes);
  if (image == null) {
    return null;
  }

  final width = image.width;
  final height = image.height;
  final x = position.dx.floor().clamp(0, width - 1);
  final y = position.dy.floor().clamp(0, height - 1);

  final before = _cloneRaster(image);
  img.fillFlood(
    image,
    x: x,
    y: y,
    color: _toImageColor(fillColor),
    threshold: tolerance,
    compareAlpha: true,
  );

  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;

  for (var py = 0; py < height; py++) {
    for (var px = 0; px < width; px++) {
      final beforePixel = before.getPixel(px, py);
      final afterPixel = image.getPixel(px, py);
      if (beforePixel == afterPixel) {
        continue;
      }
      if (px < minX) {
        minX = px;
      }
      if (py < minY) {
        minY = py;
      }
      if (px > maxX) {
        maxX = px;
      }
      if (py > maxY) {
        maxY = py;
      }
    }
  }

  if (maxX < 0) {
    return null;
  }

  final patchWidth = maxX - minX + 1;
  final patchHeight = maxY - minY + 1;
  final patch = img.Image(width: patchWidth, height: patchHeight, numChannels: 4);

  for (var py = 0; py < patchHeight; py++) {
    for (var px = 0; px < patchWidth; px++) {
      final sourceX = minX + px;
      final sourceY = minY + py;
      final beforePixel = before.getPixel(sourceX, sourceY);
      final afterPixel = image.getPixel(sourceX, sourceY);
      if (beforePixel == afterPixel) {
        patch.setPixelRgba(px, py, 0, 0, 0, 0);
      } else {
        patch.setPixel(px, py, afterPixel);
      }
    }
  }

  final uiImage = await rasterImageToUiImage(patch);
  final bounds = Rect.fromLTWH(
    minX.toDouble(),
    minY.toDouble(),
    patchWidth.toDouble(),
    patchHeight.toDouble(),
  );

  return Stroke(
    color: fillColor,
    brushSize: 0,
    shape: StrokeShape.raster,
    points: [bounds.topLeft],
    rasterImage: uiImage,
    rasterBounds: bounds,
  );
}

Future<CanvasSelection?> buildMagicWandSelection({
  required Size size,
  required List<PaintLayer> layers,
  ui.Image? backgroundImage,
  Color backgroundColor = defaultCanvasBackground,
  required Offset position,
  required double tolerance,
}) async {
  final rgba = await renderCanvasRgbaBytes(
    size: size,
    layers: layers,
    backgroundImage: backgroundImage,
    backgroundColor: backgroundColor,
  );
  if (rgba == null) {
    return null;
  }

  final width = size.width.ceil();
  final height = size.height.ceil();
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  final x = position.dx.floor().clamp(0, width - 1);
  final y = position.dy.floor().clamp(0, height - 1);
  final mask = img.maskFlood(
    image,
    x,
    y,
    threshold: tolerance,
    compareAlpha: true,
  );

  final contour = traceMaskContour(mask, width, height);
  if (contour.length < 3) {
    return null;
  }

  return CanvasSelection.fromPoints(contour, close: true);
}
