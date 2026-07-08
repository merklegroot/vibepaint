import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';
import 'package:vibepaint/services/ai_enhance/ai_enhance_service.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

export 'package:vibepaint/services/ai_enhance/ai_enhance_models.dart';

enum AiEnhanceAvailability {
  available,
  notConfigured,
  unsupportedPlatform,
  unknown,
}

/// Crop of the active layer (or selection) prepared as AI input.
class AiEnhanceSource {
  const AiEnhanceSource({
    required this.pngBytes,
    required this.placement,
  });

  final Uint8List pngBytes;

  /// Document-space rect where the result should be placed on Apply.
  final Rect placement;
}

final _service = AiEnhanceService();

final _progressController = StreamController<AiEnhanceProgress>.broadcast();

/// Whether AI Enhance can run for the active provider.
Future<AiEnhanceAvailability> checkAiEnhanceAvailability() async {
  if (kIsWeb) {
    return AiEnhanceAvailability.unsupportedPlatform;
  }

  try {
    final configured = await _service.isConfigured();
    if (configured) {
      return AiEnhanceAvailability.available;
    }
    return AiEnhanceAvailability.notConfigured;
  } on Object {
    return AiEnhanceAvailability.unknown;
  }
}

Stream<AiEnhanceProgress> aiEnhanceProgressStream() {
  return _progressController.stream;
}

void _emitProgress(AiEnhanceProgress progress) {
  if (!_progressController.isClosed) {
    _progressController.add(progress);
  }
}

/// Sends [sourcePng] to the configured AI provider for enhancement.
Future<AiEnhanceResult?> enhanceSketch({
  required Uint8List sourcePng,
  String prompt = defaultAiEnhancePrompt,
}) async {
  if (kIsWeb) {
    return null;
  }

  return _service.enhanceSketch(
    sourcePng: sourcePng,
    prompt: prompt,
    onProgress: _emitProgress,
  );
}

/// Renders the active layer strokes and optionally crops to [selection].
Future<AiEnhanceSource?> captureAiEnhanceSource({
  required Size documentSize,
  required List<Stroke> strokes,
  CanvasSelection? selection,
}) async {
  if (documentSize.isEmpty) {
    return null;
  }

  final rgba = await renderStrokesRgbaBytes(
    size: documentSize,
    strokes: strokes,
  );
  if (rgba == null) {
    return null;
  }

  final full = img.Image.fromBytes(
    width: documentSize.width.ceil(),
    height: documentSize.height.ceil(),
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  late final img.Image cropped;
  late final Rect placement;

  if (selection == null || selection.isEmpty) {
    final content = _contentBounds(full);
    if (content == null) {
      return null;
    }
    placement = content;
    cropped = img.copyCrop(
      full,
      x: content.left.floor(),
      y: content.top.floor(),
      width: content.width.ceil().clamp(1, full.width),
      height: content.height.ceil().clamp(1, full.height),
    );
  } else {
    final bounds = selection.bounds.intersect(Offset.zero & documentSize);
    if (bounds.isEmpty) {
      return null;
    }
    placement = bounds;
    cropped = img.Image(
      width: bounds.width.ceil().clamp(1, full.width),
      height: bounds.height.ceil().clamp(1, full.height),
      numChannels: 4,
    );
    final path = selection.path;
    for (var y = 0; y < cropped.height; y++) {
      for (var x = 0; x < cropped.width; x++) {
        final doc = Offset(bounds.left + x + 0.5, bounds.top + y + 0.5);
        if (!path.contains(doc)) {
          continue;
        }
        final sx = doc.dx.floor().clamp(0, full.width - 1);
        final sy = doc.dy.floor().clamp(0, full.height - 1);
        cropped.setPixel(x, y, full.getPixel(sx, sy));
      }
    }
  }

  if (!_hasVisiblePixels(cropped)) {
    return null;
  }

  // AI providers work best with opaque sketches on a white background.
  final prepared = _flattenOntoWhite(cropped);

  return AiEnhanceSource(
    pngBytes: Uint8List.fromList(img.encodePng(prepared)),
    placement: placement,
  );
}

img.Image _flattenOntoWhite(img.Image source) {
  final out = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  img.fill(out, color: img.ColorRgba8(255, 255, 255, 255));
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final a = pixel.a;
      if (a == 0) {
        continue;
      }
      if (a == 255) {
        out.setPixel(x, y, pixel);
        continue;
      }
      final alpha = a / 255.0;
      final r = (pixel.r * alpha + 255 * (1 - alpha)).round().clamp(0, 255);
      final g = (pixel.g * alpha + 255 * (1 - alpha)).round().clamp(0, 255);
      final b = (pixel.b * alpha + 255 * (1 - alpha)).round().clamp(0, 255);
      out.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return out;
}

Future<Stroke> strokeFromAiEnhanceResult({
  required AiEnhanceResult result,
  required Rect placement,
}) async {
  final uiImage = await decodeImageBytes(result.pngBytes);

  final fitted = _fittedBounds(
    sourceWidth: uiImage.width.toDouble(),
    sourceHeight: uiImage.height.toDouble(),
    target: placement,
  );

  return Stroke(
    color: const Color(0x00000000),
    brushSize: 0,
    shape: StrokeShape.raster,
    points: [fitted.topLeft],
    rasterImage: uiImage,
    rasterBounds: fitted,
  );
}

Rect? _contentBounds(img.Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a == 0) {
        continue;
      }
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  if (maxX < 0) {
    return null;
  }
  return Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    (maxX + 1).toDouble(),
    (maxY + 1).toDouble(),
  );
}

bool _hasVisiblePixels(img.Image image) {
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a != 0) {
        return true;
      }
    }
  }
  return false;
}

Rect _fittedBounds({
  required double sourceWidth,
  required double sourceHeight,
  required Rect target,
}) {
  if (sourceWidth <= 0 || sourceHeight <= 0 || target.isEmpty) {
    return target;
  }
  final scaleX = target.width / sourceWidth;
  final scaleY = target.height / sourceHeight;
  final fit = scaleX < scaleY ? scaleX : scaleY;
  final width = sourceWidth * fit;
  final height = sourceHeight * fit;
  return Rect.fromCenter(
    center: target.center,
    width: width,
    height: height,
  );
}
