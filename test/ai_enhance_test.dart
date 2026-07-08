import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/ai_enhance.dart';

void main() {
  test('captureAiEnhanceSource returns null for empty layer', () async {
    final source = await captureAiEnhanceSource(
      documentSize: const Size(64, 64),
      strokes: const [],
    );
    expect(source, isNull);
  });

  test('captureAiEnhanceSource crops visible freehand content', () async {
    final stroke = Stroke(
      color: const Color(0xFFFF0000),
      brushSize: 4,
      points: const [
        Offset(10, 10),
        Offset(20, 12),
        Offset(30, 18),
      ],
    );

    final source = await captureAiEnhanceSource(
      documentSize: const Size(64, 64),
      strokes: [stroke],
    );

    expect(source, isNotNull);
    expect(source!.pngBytes, isNotEmpty);
    expect(source.placement.left, lessThan(15));
    expect(source.placement.top, lessThan(15));

    final decoded = img.decodePng(source.pngBytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, greaterThan(0));
    expect(decoded.height, greaterThan(0));
  });
}
