import 'package:flutter/foundation.dart';
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

  test('rejects touch pointers on desktop', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      expect(
        acceptsCanvasDrawingPointerKind(PointerDeviceKind.touch, 0),
        isFalse,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('accepts touch pointers on mobile', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      expect(
        acceptsCanvasDrawingPointerKind(PointerDeviceKind.touch, 0),
        isTrue,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
