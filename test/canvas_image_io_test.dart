import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renderCanvasToPng returns PNG bytes for strokes', () async {
    final bytes = await renderCanvasToPng(
      size: const Size(100, 100),
      strokes: [
        Stroke(
          color: Colors.red,
          brushSize: 4,
          points: const [Offset(10, 10), Offset(80, 80)],
        ),
      ],
    );

    expect(bytes.length, greaterThan(100));
    expect(bytes[0], equals(0x89));
    expect(String.fromCharCodes(bytes.sublist(1, 4)), equals('PNG'));
  });
}
