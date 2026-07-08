import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';

const _channel = MethodChannel('vibepaint/ai_enhance');

/// Default prompt seed for Image Playground when enhancing a sketch.
const defaultAiEnhancePrompt =
    'Polish and color this sketch into a clean finished illustration';

enum AiEnhanceAvailability {
  available,
  unsupportedPlatform,
  unavailableOnDevice,
  unknown,
}

class AiEnhanceResult {
  const AiEnhanceResult({
    required this.pngBytes,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;
  final int width;
  final int height;
}

/// Crop of the active layer (or selection) prepared as Playground input.
class AiEnhanceSource {
  const AiEnhanceSource({
    required this.pngBytes,
    required this.placement,
  });

  final Uint8List pngBytes;

  /// Document-space rect where the result should be placed on Apply.
  final Rect placement;
}

Future<AiEnhanceAvailability> checkAiEnhanceAvailability() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
    return AiEnhanceAvailability.unsupportedPlatform;
  }

  try {
    final available = await _channel.invokeMethod<bool>('isAvailable');
    if (available == true) {
      return AiEnhanceAvailability.available;
    }
    return AiEnhanceAvailability.unavailableOnDevice;
  } on MissingPluginException {
    return AiEnhanceAvailability.unavailableOnDevice;
  } on Object {
    return AiEnhanceAvailability.unknown;
  }
}

Future<AiEnhanceResult?> presentAiEnhance({
  required Uint8List sourcePng,
  String prompt = defaultAiEnhancePrompt,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
    return null;
  }

  try {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'present',
      <String, Object>{
        'pngBytes': sourcePng,
        'prompt': prompt,
      },
    );
    if (result == null) {
      return null;
    }

    final bytes = result['pngBytes'];
    final width = result['width'];
    final height = result['height'];
    final png = switch (bytes) {
      final Uint8List b => b,
      final ByteBuffer buffer => buffer.asUint8List(),
      final List<int> list => Uint8List.fromList(list),
      _ => null,
    };
    if (png == null || width is! int || height is! int) {
      return null;
    }
    return AiEnhanceResult(pngBytes: png, width: width, height: height);
  } on PlatformException catch (error) {
    throw AiEnhanceException(error.code, error.message ?? 'AI Enhance failed');
  }
}

class AiEnhanceException implements Exception {
  AiEnhanceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
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

  return AiEnhanceSource(
    pngBytes: Uint8List.fromList(img.encodePng(cropped)),
    placement: placement,
  );
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
