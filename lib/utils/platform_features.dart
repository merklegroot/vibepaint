import 'package:flutter/foundation.dart';
import 'package:vibepaint/models/paint_tool.dart';

/// True on Android and iOS — a trimmed-down paint experience.
bool get isMobilePaintPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Drawing tools exposed on mobile (core brush workflow only).
const List<PaintTool> mobilePaintTools = [
  PaintTool.brush,
  PaintTool.pencil,
  PaintTool.eraser,
  PaintTool.line,
  PaintTool.fillBucket,
  PaintTool.eyedropper,
];

List<PaintTool> get availablePaintTools =>
    isMobilePaintPlatform ? mobilePaintTools : PaintTool.values;

bool get supportsLayersPanel => !isMobilePaintPlatform;

bool get supportsSelectionTools => !isMobilePaintPlatform;

bool get supportsAiEnhance => !kIsWeb && !isMobilePaintPlatform;

bool get supportsImageMenu => !isMobilePaintPlatform;

bool get supportsInWindowMenuBar =>
    defaultTargetPlatform != TargetPlatform.macOS && !isMobilePaintPlatform;

bool get supportsMobileFileBar => isMobilePaintPlatform;

bool get supportsTouchDrawing => isMobilePaintPlatform;

String get viewportInteractionHint => isMobilePaintPlatform
    ? 'Pinch to zoom · drag to draw'
    : 'Scroll: zoom · Space+drag or middle-drag: pan · use keyboard zoom shortcuts';
