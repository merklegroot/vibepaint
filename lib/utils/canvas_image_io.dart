import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/painters/canvas_painter.dart';
import 'package:vibepaint/theme/color_wells.dart';

Future<ui.Image> renderCanvasToUiImage({
  required Size size,
  required List<PaintLayer> layers,
  ui.Image? backgroundImage,
  Color backgroundColor = defaultCanvasBackground,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  CanvasPainter.paintCanvas(
    canvas: canvas,
    size: size,
    layers: layers,
    activeLayerIndex: 0,
    backgroundImage: backgroundImage,
    backgroundColor: backgroundColor,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    size.width.ceil(),
    size.height.ceil(),
  );
  picture.dispose();
  return image;
}

Future<img.Image> uiImageToRasterImage(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    throw StateError('Failed to read canvas pixels');
  }

  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: byteData.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}

Uint8List encodeRasterImage(
  img.Image image,
  ImageFileFormat format,
) {
  return switch (format) {
    ImageFileFormat.png => Uint8List.fromList(img.encodePng(image)),
    ImageFileFormat.jpeg =>
      Uint8List.fromList(img.encodeJpg(image, quality: 95)),
    ImageFileFormat.bmp => Uint8List.fromList(img.encodeBmp(image)),
    ImageFileFormat.gif => Uint8List.fromList(img.encodeGif(image)),
    ImageFileFormat.webp => Uint8List.fromList(img.encodeWebP(image)),
  };
}

Future<Uint8List?> renderStrokesRgbaBytes({
  required Size size,
  required List<Stroke> strokes,
}) async {
  if (size.width <= 0 || size.height <= 0) {
    return null;
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final bounds = Offset.zero & size;

  canvas.saveLayer(bounds, Paint());
  for (final stroke in strokes) {
    CanvasPainter.paintStroke(canvas, stroke, canvasBounds: bounds);
  }
  canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    size.width.ceil(),
    size.height.ceil(),
  );
  picture.dispose();

  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

Future<Uint8List?> renderCanvasRgbaBytes({
  required Size size,
  required List<PaintLayer> layers,
  ui.Image? backgroundImage,
  Color backgroundColor = defaultCanvasBackground,
}) async {
  final uiImage = await renderCanvasToUiImage(
    size: size,
    layers: layers,
    backgroundImage: backgroundImage,
    backgroundColor: backgroundColor,
  );

  try {
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData?.buffer.asUint8List();
  } finally {
    uiImage.dispose();
  }
}

Color? readCanvasPixel({
  required Uint8List rgba,
  required int width,
  required int height,
  required Offset position,
}) {
  if (width <= 0 || height <= 0 || rgba.isEmpty) {
    return null;
  }

  final x = position.dx.floor().clamp(0, width - 1);
  final y = position.dy.floor().clamp(0, height - 1);
  final index = (y * width + x) * 4;
  if (index + 3 >= rgba.length) {
    return null;
  }

  return Color.fromARGB(
    rgba[index + 3],
    rgba[index],
    rgba[index + 1],
    rgba[index + 2],
  );
}

Future<Uint8List> renderCanvasToBytes({
  required Size size,
  required List<PaintLayer> layers,
  ui.Image? backgroundImage,
  Color backgroundColor = defaultCanvasBackground,
  ImageFileFormat format = ImageFileFormat.png,
}) async {
  final uiImage = await renderCanvasToUiImage(
    size: size,
    layers: layers,
    backgroundImage: backgroundImage,
    backgroundColor: backgroundColor,
  );

  try {
    final rasterImage = await uiImageToRasterImage(uiImage);
    return encodeRasterImage(rasterImage, format);
  } finally {
    uiImage.dispose();
  }
}

Future<ui.Image> rasterImageToUiImage(img.Image image) async {
  final bytes = img.encodePng(image);
  return decodeImageBytes(Uint8List.fromList(bytes));
}

Future<ui.Image> decodeImageBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
