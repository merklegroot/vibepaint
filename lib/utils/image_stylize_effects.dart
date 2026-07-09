import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_adjustments.dart';
import 'package:vibepaint/utils/image_effect_helpers.dart';

img.Image edgeDetectEffect(img.Image source, {required double angle}) {
  final edges = img.sobel(cloneImage(source), amount: 1.5);
  final radians = angle * math.pi / 180;
  final dirX = math.cos(radians);
  final dirY = math.sin(radians);

  for (final frame in edges.frames) {
    for (final p in frame) {
      final lum = p.luminanceNormalized;
      final shaded = (lum * 255).round().clamp(0, 255);
      final tint = ((dirX + 1) * 0.5 * shaded).round();
      p
        ..r = tint
        ..g = shaded
        ..b = ((dirY + 1) * 0.5 * shaded).round();
    }
  }
  return edges;
}

img.Image embossEffect(img.Image source, {required double angle}) {
  return img.convolution(
    cloneImage(source),
    filter: rotatedEmbossKernel(angle),
    div: 1,
    offset: 127,
    amount: 1,
  );
}

img.Image outlineEffect(
  img.Image source, {
  required double thickness,
  required double intensity,
}) {
  final strength = normalizedAmount(intensity);
  final radius = thickness.round().clamp(1, 8);
  if (strength == 0) {
    return cloneImage(source);
  }

  final edges = img.sobel(cloneImage(source), amount: strength * 2);
  final result = cloneImage(source);

  for (var pass = 1; pass < radius; pass++) {
    img.sobel(edges, amount: 0.5);
  }

  for (final frame in result.frames) {
    final edgeFrame = edges.frames[frame.frameIndex];
    for (final p in frame) {
      final edge = edgeFrame.getPixel(p.x, p.y);
      final lum = edge.luminanceNormalized;
      if (lum > 0.15 * strength) {
        final mix = (lum * strength).clamp(0.0, 1.0);
        p
          ..r = (p.r * (1 - mix)).round()
          ..g = (p.g * (1 - mix)).round()
          ..b = (p.b * (1 - mix)).round();
      }
    }
  }
  return result;
}

img.Image reliefEffect(img.Image source, {required double angle}) {
  final embossed = img.convolution(
    cloneImage(source),
    filter: rotatedEmbossKernel(angle),
    div: 1,
    offset: 127,
    amount: 1,
  );
  final result = cloneImage(source);

  for (final frame in result.frames) {
    final embossFrame = embossed.frames[frame.frameIndex];
    for (final p in frame) {
      final e = embossFrame.getPixel(p.x, p.y);
      final shade = (e.luminanceNormalized - 0.5) * 2;
      final highlight = shade.clamp(0.0, 1.0);
      final shadow = (-shade).clamp(0.0, 1.0);
      p
        ..r = (p.r * (1 + highlight * 0.4) * (1 - shadow * 0.3))
            .round()
            .clamp(0, 255)
        ..g = (p.g * (1 + highlight * 0.4) * (1 - shadow * 0.3))
            .round()
            .clamp(0, 255)
        ..b = (p.b * (1 + highlight * 0.4) * (1 - shadow * 0.3))
            .round()
            .clamp(0, 255);
    }
  }
  return result;
}
