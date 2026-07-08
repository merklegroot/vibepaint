import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/models/paint_layer.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/stroke_history.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('readCanvasPixel returns color at position', () {
    final rgba = Uint8List.fromList([
      255, 0, 0, 255, 0, 255, 0, 255,
      0, 0, 255, 255, 255, 255, 255, 255,
    ]);

    expect(
      readCanvasPixel(
        rgba: rgba,
        width: 2,
        height: 2,
        position: const Offset(1, 0),
      ),
      const Color(0xFF00FF00),
    );
  });

  test('renderCanvasToBytes returns PNG bytes for strokes', () async {
    final layer = PaintLayer(
      name: 'Layer 1',
      history: StrokeHistory([
        Stroke(
          color: Colors.red,
          brushSize: 4,
          points: const [Offset(10, 10), Offset(80, 80)],
        ),
      ]),
    );

    final bytes = await renderCanvasToBytes(
      size: const Size(100, 100),
      layers: [layer],
      format: ImageFileFormat.png,
    );

    expect(bytes.length, greaterThan(100));
    expect(bytes[0], equals(0x89));
    expect(String.fromCharCodes(bytes.sublist(1, 4)), equals('PNG'));
  });

  test('renderCanvasToBytes returns JPEG bytes for strokes', () async {
    final layer = PaintLayer(
      name: 'Layer 1',
      history: StrokeHistory([
        Stroke(
          color: Colors.blue,
          brushSize: 4,
          points: const [Offset(10, 10), Offset(80, 80)],
        ),
      ]),
    );

    final bytes = await renderCanvasToBytes(
      size: const Size(100, 100),
      layers: [layer],
      format: ImageFileFormat.jpeg,
    );

    expect(bytes.length, greaterThan(100));
    expect(bytes[0], equals(0xFF));
    expect(bytes[1], equals(0xD8));
  });

  test('renderCanvasToBytes skips hidden layers', () async {
    final visibleLayer = PaintLayer(
      name: 'Visible',
      history: StrokeHistory([
        Stroke(
          color: Colors.red,
          brushSize: 8,
          points: const [Offset(10, 10), Offset(90, 90)],
        ),
      ]),
    );
    final hiddenLayer = PaintLayer(
      name: 'Hidden',
      history: StrokeHistory([
        Stroke(
          color: Colors.blue,
          brushSize: 8,
          points: const [Offset(20, 20), Offset(80, 80)],
        ),
      ]),
      visible: false,
    );

    final bytes = await renderCanvasToBytes(
      size: const Size(100, 100),
      layers: [visibleLayer, hiddenLayer],
      format: ImageFileFormat.png,
    );

    expect(bytes.length, greaterThan(100));
  });

  test('imageFormatFromPath recognizes common extensions', () {
    expect(imageFormatFromPath('/tmp/sketch.JPG'), ImageFileFormat.jpeg);
    expect(imageFormatFromPath('/tmp/sketch.webp'), ImageFileFormat.webp);
    expect(imageFormatFromPath('/tmp/sketch'), isNull);
  });
}
