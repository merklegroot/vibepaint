import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_adjustments.dart';

int _radiusFromAmount(double amount, {int maxRadius = 40}) {
  return (amount / 100 * maxRadius).round().clamp(0, maxRadius);
}

img.Image gaussianBlurEffect(img.Image source, {required double radius}) {
  final r = radius.round().clamp(0, 80);
  if (r <= 0) {
    return cloneImage(source);
  }
  return img.gaussianBlur(cloneImage(source), radius: r);
}

img.Image unfocusEffect(img.Image source, {required double amount}) {
  final radius = _radiusFromAmount(amount, maxRadius: 60);
  if (radius <= 0) {
    return cloneImage(source);
  }
  var copy = cloneImage(source);
  copy = img.gaussianBlur(copy, radius: radius);
  if (radius > 8) {
    copy = img.gaussianBlur(copy, radius: (radius * 0.35).round().clamp(1, 20));
  }
  return copy;
}

img.Image motionBlurEffect(
  img.Image source, {
  required double angle,
  required double distance,
}) {
  final samples = distance.round().clamp(0, 80);
  if (samples <= 0) {
    return cloneImage(source);
  }

  final radians = angle * math.pi / 180;
  final dx = math.cos(radians);
  final dy = math.sin(radians);
  final result = cloneImage(source);

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      num r = 0;
      num g = 0;
      num b = 0;
      num a = 0;
      var count = 0;

      for (var step = -samples; step <= samples; step++) {
        final sx = (x + dx * step).round().clamp(0, source.width - 1);
        final sy = (y + dy * step).round().clamp(0, source.height - 1);
        final pixel = source.getPixel(sx, sy);
        r += pixel.r;
        g += pixel.g;
        b += pixel.b;
        a += pixel.a;
        count++;
      }

      result.setPixelRgba(
        x,
        y,
        (r / count).round(),
        (g / count).round(),
        (b / count).round(),
        (a / count).round(),
      );
    }
  }

  return result;
}

img.Image zoomBlurEffect(img.Image source, {required double amount}) {
  final samples = _radiusFromAmount(amount, maxRadius: 50);
  if (samples <= 0) {
    return cloneImage(source);
  }

  final centerX = source.width / 2;
  final centerY = source.height / 2;
  final result = cloneImage(source);

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final vx = x - centerX;
      final vy = y - centerY;
      final length = math.sqrt(vx * vx + vy * vy);
      if (length < 0.5) {
        continue;
      }

      num r = 0;
      num g = 0;
      num b = 0;
      num a = 0;
      var count = 0;

      for (var step = 0; step <= samples; step++) {
        final scale = 1 + (step / samples) * 0.75;
        final sx = (centerX + vx * scale).round().clamp(0, source.width - 1);
        final sy = (centerY + vy * scale).round().clamp(0, source.height - 1);
        final pixel = source.getPixel(sx, sy);
        r += pixel.r;
        g += pixel.g;
        b += pixel.b;
        a += pixel.a;
        count++;
      }

      result.setPixelRgba(
        x,
        y,
        (r / count).round(),
        (g / count).round(),
        (b / count).round(),
        (a / count).round(),
      );
    }
  }

  return result;
}

img.Image radialBlurEffect(img.Image source, {required double amount}) {
  final samples = _radiusFromAmount(amount, maxRadius: 36);
  if (samples <= 0) {
    return cloneImage(source);
  }

  final centerX = source.width / 2;
  final centerY = source.height / 2;
  final result = cloneImage(source);

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final vx = x - centerX;
      final vy = y - centerY;
      final radius = math.sqrt(vx * vx + vy * vy);
      if (radius < 0.5) {
        continue;
      }

      final baseAngle = math.atan2(vy, vx);
      num r = 0;
      num g = 0;
      num b = 0;
      num a = 0;
      var count = 0;

      for (var step = -samples; step <= samples; step++) {
        final angle = baseAngle + (step / samples) * 0.35;
        final sx = (centerX + math.cos(angle) * radius).round().clamp(
              0,
              source.width - 1,
            );
        final sy = (centerY + math.sin(angle) * radius).round().clamp(
              0,
              source.height - 1,
            );
        final pixel = source.getPixel(sx, sy);
        r += pixel.r;
        g += pixel.g;
        b += pixel.b;
        a += pixel.a;
        count++;
      }

      result.setPixelRgba(
        x,
        y,
        (r / count).round(),
        (g / count).round(),
        (b / count).round(),
        (a / count).round(),
      );
    }
  }

  return result;
}

img.Image fragmentEffect(
  img.Image source, {
  required double fragmentSize,
  required double distance,
}) {
  final block = fragmentSize.round().clamp(2, 128);
  final offset = distance.round().clamp(0, 80);
  if (offset <= 0) {
    return cloneImage(source);
  }

  final result = cloneImage(source);
  final rng = math.Random(7);

  for (var blockY = 0; blockY < source.height; blockY += block) {
    for (var blockX = 0; blockX < source.width; blockX += block) {
      final shiftX = rng.nextInt(offset * 2 + 1) - offset;
      final shiftY = rng.nextInt(offset * 2 + 1) - offset;
      final maxY = math.min(blockY + block, source.height);
      final maxX = math.min(blockX + block, source.width);

      for (var y = blockY; y < maxY; y++) {
        for (var x = blockX; x < maxX; x++) {
          final sx = (x + shiftX).clamp(0, source.width - 1);
          final sy = (y + shiftY).clamp(0, source.height - 1);
          final pixel = source.getPixel(sx, sy);
          result.setPixel(x, y, pixel);
        }
      }
    }
  }

  return result;
}
