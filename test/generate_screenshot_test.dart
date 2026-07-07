import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/demo/screenshot_demo.dart';
import 'package:vibepaint/main.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/screens/paint_screen.dart';

import 'test_fonts.dart';

void main() {
  setUpAll(() async {
    await loadTestFonts();
  });

  testWidgets(
    'generate README screenshot',
    (tester) async {
    const size = Size(1280, 720);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('screenshot'),
        child: VibePaintApp(
          home: PaintScreen(
            initialStrokes: screenshotDemoStrokes(),
            initialColorIndex: 3,
            initialTool: PaintTool.rectangle,
            initialShapeStyle: ShapeStyle.filledOutline,
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('screenshot')),
      matchesGoldenFile('../docs/screenshot.png'),
    );
  }, tags: 'golden');
}
