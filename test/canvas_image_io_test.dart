import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renderCanvasToBytes returns PNG bytes for strokes', () async {
    final bytes = await renderCanvasToBytes(
      size: const Size(100, 100),
      strokes: [
        Stroke(
          color: Colors.red,
          brushSize: 4,
          points: const [Offset(10, 10), Offset(80, 80)],
        ),
      ],
      format: ImageFileFormat.png,
    );

    expect(bytes.length, greaterThan(100));
    expect(bytes[0], equals(0x89));
    expect(String.fromCharCodes(bytes.sublist(1, 4)), equals('PNG'));
  });

  test('renderCanvasToBytes returns JPEG bytes for strokes', () async {
    final bytes = await renderCanvasToBytes(
      size: const Size(100, 100),
      strokes: [
        Stroke(
          color: Colors.blue,
          brushSize: 4,
          points: const [Offset(10, 10), Offset(80, 80)],
        ),
      ],
      format: ImageFileFormat.jpeg,
    );

    expect(bytes.length, greaterThan(100));
    expect(bytes[0], equals(0xFF));
    expect(bytes[1], equals(0xD8));
  });

  test('imageFormatFromPath recognizes common extensions', () {
    expect(imageFormatFromPath('/tmp/sketch.JPG'), ImageFileFormat.jpeg);
    expect(imageFormatFromPath('/tmp/sketch.webp'), ImageFileFormat.webp);
    expect(imageFormatFromPath('/tmp/sketch'), isNull);
  });
}
