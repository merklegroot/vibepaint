import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/canvas_pointer_input.dart';

void main() {
  test('accepts mouse pointer with primary button pressed', () {
    expect(
      acceptsCanvasDrawingPointerKind(
        PointerDeviceKind.mouse,
        kPrimaryMouseButton,
      ),
      isTrue,
    );
  });

  test('rejects mouse pointer without button pressed', () {
    expect(
      acceptsCanvasDrawingPointerKind(PointerDeviceKind.mouse, 0),
      isFalse,
    );
  });

  test('rejects trackpad finger contacts', () {
    expect(
      acceptsCanvasDrawingPointerKind(PointerDeviceKind.trackpad, 0),
      isFalse,
    );
  });

  test('accepts stylus pointers', () {
    expect(
      acceptsCanvasDrawingPointerKind(PointerDeviceKind.stylus, 0),
      isTrue,
    );
  });
}
