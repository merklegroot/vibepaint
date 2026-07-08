import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/painters/canvas_painter.dart';

Future<ui.Image> renderCanvasToUiImage({
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

Future<Uint8List> renderCanvasToBytes({
  required Size size,
  required List<Stroke> strokes,
  ui.Image? backgroundImage,
  ImageFileFormat format = ImageFileFormat.png,
}) async {
  final uiImage = await renderCanvasToUiImage(
    size: size,
    strokes: strokes,
    backgroundImage: backgroundImage,
  );

  try {
    final rasterImage = await uiImageToRasterImage(uiImage);
    return encodeRasterImage(rasterImage, format);
  } finally {
    uiImage.dispose();
  }
}

Future<ui.Image> decodeImageBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
