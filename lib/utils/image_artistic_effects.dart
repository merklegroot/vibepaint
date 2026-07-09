import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_adjustments.dart';

double _normalizedAmount(double value) => (value / 100).clamp(0.0, 1.0);

img.Image inkSketch(
  img.Image source, {
  required double amount,
}) {
  final strength = _normalizedAmount(amount);
  if (strength == 0) {
    return cloneImage(source);
  }

  var copy = cloneImage(source);
  copy = img.grayscale(copy);
  copy = img.contrast(copy, contrast: 130 + (strength * 70));
  copy = img.sketch(copy, amount: 0.65 + (strength * 0.35));
  copy = img.adjustColor(copy, brightness: 1.05, contrast: 1.1);
  return copy;
}

img.Image pencilSketch(
  img.Image source, {
  required double amount,
}) {
  final strength = _normalizedAmount(amount);
  if (strength == 0) {
    return cloneImage(source);
  }

  var copy = cloneImage(source);
  copy = img.adjustColor(
    copy,
    saturation: 1 - (strength * 0.85),
    brightness: 1.04,
  );
  copy = img.sketch(copy, amount: 0.5 + (strength * 0.5));
  return copy;
}

img.Image oilPainting(
  img.Image source, {
  required double amount,
  required double brushSize,
}) {
  final strength = _normalizedAmount(amount);
  if (strength == 0) {
    return cloneImage(source);
  }

  final weight = 2 + brushSize.clamp(1, 20);
  final colorLevels = (56 - (strength * 40)).round().clamp(8, 56);

  var copy = cloneImage(source);
  copy = img.smooth(copy, weight: weight);
  copy = img.smooth(copy, weight: weight);
  copy = img.quantize(copy, numberOfColors: colorLevels);
  copy = img.smooth(copy, weight: weight * 0.75);
  copy = img.adjustColor(
    copy,
    saturation: 1 + (strength * 0.15),
    contrast: 1 + (strength * 0.08),
  );
  return copy;
}
