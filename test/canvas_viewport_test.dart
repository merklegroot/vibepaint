import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/canvas_viewport.dart';

void main() {
  test('viewportToDocument and documentToViewport are inverse', () {
    const viewport = CanvasViewport(scale: 2, pan: Offset(40, 20));
    const documentPoint = Offset(100, 50);

    expect(
      viewport.viewportToDocument(viewport.documentToViewport(documentPoint)),
      documentPoint,
    );
  });

  test('zoomAt keeps the focal document point under the cursor', () {
    const viewport = CanvasViewport();
    const focal = Offset(200, 150);
    final zoomed = viewport.zoomAt(focal, 2);

    expect(
      zoomed.documentToViewport(zoomed.viewportToDocument(focal)),
      focal,
    );
  });

  test('fitToWindow centers and scales down large documents', () {
    const viewport = CanvasViewport();
    final fitted = viewport.fitToWindow(
      const Size(800, 600),
      const Size(1600, 1200),
    );

    expect(fitted.scale, 0.5);
    expect(fitted.pan, Offset.zero);
  });

  test('zoomAt clamps to min and max scale', () {
    const viewport = CanvasViewport();
    expect(
      viewport.zoomAt(Offset.zero, 0.01).scale,
      CanvasViewport.minScale,
    );
    expect(
      viewport.zoomAt(Offset.zero, 100).scale,
      CanvasViewport.maxScale,
    );
  });

  test('zoomPercentLabel formats small zoom levels with a decimal', () {
    const viewport = CanvasViewport(scale: 0.5);
    expect(viewport.zoomPercentLabel, '50');
    expect(const CanvasViewport(scale: 0.05).zoomPercentLabel, '5.0');
  });
}
