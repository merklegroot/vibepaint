import 'package:flutter/gestures.dart';
import 'package:vibepaint/utils/platform_features.dart';

/// Returns whether a pointer event should start or continue canvas input.
///
/// Trackpad finger contacts on macOS are reported as [PointerDeviceKind.trackpad]
/// without a pressed mouse button; those should not draw on the canvas.
bool acceptsCanvasDrawingPointer(PointerEvent event) {
  return acceptsCanvasDrawingPointerKind(event.kind, event.buttons);
}

bool acceptsCanvasDrawingPointerKind(PointerDeviceKind kind, int buttons) {
  return switch (kind) {
    PointerDeviceKind.mouse => (buttons & kPrimaryMouseButton) != 0,
    PointerDeviceKind.stylus || PointerDeviceKind.invertedStylus => true,
    PointerDeviceKind.touch when supportsTouchDrawing => true,
    _ => false,
  };
}
