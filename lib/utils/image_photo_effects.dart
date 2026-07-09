import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_adjustments.dart';
import 'package:vibepaint/utils/image_effect_helpers.dart';

img.Image glowEffect(
  img.Image source, {
  required double radius,
  required double brightness,
  required double contrast,
}) {
  var copy = cloneImage(source);
  final strength = normalizedAmount(radius);
  final blurRadius = (strength * 24).round().clamp(0, 32);

  if (blurRadius > 0) {
    copy = img.edgeGlow(copy, amount: 0.5 + strength * 1.5);
    copy = img.gaussianBlur(copy, radius: blurRadius);
  }

  final b = 0.7 + normalizedAmount(brightness) * 0.8;
  final c = 0.6 + normalizedAmount(contrast) * 1.2;
  copy = img.adjustColor(
    copy,
    brightness: b,
    contrast: c,
    saturation: 1 - strength * 0.35,
  );
  return copy;
}

img.Image sharpenEffect(img.Image source, {required double amount}) {
  final strength = normalizedAmount(amount);
  if (strength == 0) {
    return cloneImage(source);
  }

  const filter = [0, -1, 0, -1, 5, -1, 0, -1, 0];
  return img.convolution(
    cloneImage(source),
    filter: filter,
    amount: strength * 2,
  );
}

img.Image softenPortraitEffect(
  img.Image source, {
  required double softness,
  required double lighting,
  required double warmth,
}) {
  final soft = normalizedAmount(softness);
  final light = normalizedAmount(lighting);
  final warm = normalizedAmount(warmth);

  var copy = cloneImage(source);
  final blurRadius = (soft * 10).round().clamp(0, 12);
  if (blurRadius > 0) {
    final blurred = img.gaussianBlur(cloneImage(source), radius: blurRadius);
    final mix = soft * 0.7;
    for (final frame in copy.frames) {
      final blurFrame = blurred.frames[frame.frameIndex];
      for (final p in frame) {
        final b = blurFrame.getPixel(p.x, p.y);
        p
          ..r = (p.r * (1 - mix) + b.r * mix).round()
          ..g = (p.g * (1 - mix) + b.g * mix).round()
          ..b = (p.b * (1 - mix) + b.b * mix).round();
      }
    }
  }

  final brightness = 0.9 + light * 0.35;
  final hue = (warm - 0.5) * 30;
  copy = img.adjustColor(
    copy,
    brightness: brightness,
    hue: hue,
    saturation: 1 + soft * 0.1,
  );
  return copy;
}
