import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_adjustments.dart';
import 'package:vibepaint/utils/image_effect_helpers.dart';

img.Image bulgeEffect(img.Image source, {required double amount}) {
  final scale = (normalizedAmount(amount) - 0.5) * 1.6;
  if (scale.abs() < 0.001) {
    return cloneImage(source);
  }
  return img.bulgeDistortion(
    cloneImage(source),
    scale: scale,
    interpolation: img.Interpolation.linear,
  );
}

img.Image frostedGlassEffect(img.Image source, {required double amount}) {
  final strength = normalizedAmount(amount);
  if (strength == 0) {
    return cloneImage(source);
  }

  var copy = cloneImage(source);
  copy = img.noise(
    copy,
    strength * 35,
    type: img.NoiseType.uniform,
  );
  final radius = (strength * 4).round().clamp(1, 8);
  copy = img.gaussianBlur(copy, radius: radius);
  return copy;
}

img.Image pixelateEffect(img.Image source, {required double cellSize}) {
  final size = cellSize.round().clamp(2, 64);
  if (size <= 1) {
    return cloneImage(source);
  }
  return img.pixelate(
    cloneImage(source),
    size: size,
    mode: img.PixelateMode.average,
  );
}

img.Image polarInversionEffect(img.Image source, {required double amount}) {
  final strength = normalizedAmount(amount);
  if (strength == 0) {
    return cloneImage(source);
  }

  final orig = cloneImage(source);
  final result = cloneImage(source);
  final w = source.width;
  final h = source.height;
  final cx = w / 2;
  final cy = h / 2;
  final maxR = math.sqrt(cx * cx + cy * cy);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final r = math.sqrt(dx * dx + dy * dy);
      final theta = math.atan2(dy, dx);
      final mappedR = math.pow(r / maxR, 1 - strength * 0.8) * maxR;
      final mappedTheta = theta + strength * math.pi * (r / maxR);
      final sx = (cx + mappedR * math.cos(mappedTheta)).clamp(0, w - 1);
      final sy = (cy + mappedR * math.sin(mappedTheta)).clamp(0, h - 1);
      result.setPixel(
        x,
        y,
        sampleBilinear(orig, sx.toDouble(), sy.toDouble()),
      );
    }
  }
  return result;
}

img.Image tileReflectionEffect(
  img.Image source, {
  required double rotation,
  required double tileSize,
  required double intensity,
}) {
  final strength = normalizedAmount(intensity);
  if (strength == 0) {
    return cloneImage(source);
  }

  final grid = tileSize.clamp(4, 80);
  var copy = img.billboard(
    cloneImage(source),
    grid: grid,
    amount: strength,
  );

  if (rotation.abs() > 0.5) {
    copy = img.copyRotate(copy, angle: rotation);
    if (copy.width != source.width || copy.height != source.height) {
      copy = img.copyResize(
        copy,
        width: source.width,
        height: source.height,
        interpolation: img.Interpolation.linear,
      );
    }
  }
  return copy;
}

img.Image twistEffect(
  img.Image source, {
  required double amount,
  required double antialias,
}) {
  final strength = amount / 100 * math.pi * 2;
  if (strength.abs() < 0.001) {
    return cloneImage(source);
  }

  final interpolation =
      antialias >= 50 ? img.Interpolation.linear : img.Interpolation.nearest;
  final orig = cloneImage(source);
  final result = cloneImage(source);
  final w = source.width;
  final h = source.height;
  final cx = w / 2;
  final cy = h / 2;
  final maxR = math.sqrt(cx * cx + cy * cy);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final r = math.sqrt(dx * dx + dy * dy);
      final theta = math.atan2(dy, dx);
      final twist = strength * (1 - r / maxR);
      final srcTheta = theta - twist;
      final sx = (cx + r * math.cos(srcTheta)).clamp(0, w - 1);
      final sy = (cy + r * math.sin(srcTheta)).clamp(0, h - 1);
      result.setPixel(
        x,
        y,
        sampleBilinear(
          orig,
          sx.toDouble(),
          sy.toDouble(),
          interpolation: interpolation,
        ),
      );
    }
  }
  return result;
}
