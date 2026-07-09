import 'package:image/image.dart' as img;

img.Image cloneImage(img.Image source) {
  return img.Image.from(source);
}

img.Image autoLevel(img.Image source) {
  return img.histogramEqualization(cloneImage(source));
}

img.Image blackAndWhite(img.Image source) {
  return img.grayscale(cloneImage(source));
}

img.Image invertColors(img.Image source) {
  return img.invert(cloneImage(source));
}

img.Image applySepia(img.Image source) {
  return img.sepia(cloneImage(source));
}

img.Image applyBrightnessContrast(
  img.Image source, {
  required double brightness,
  required double contrast,
}) {
  return img.adjustColor(
    cloneImage(source),
    brightness: brightness,
    contrast: contrast,
  );
}

img.Image applyHueSaturation(
  img.Image source, {
  required double hue,
  required double saturation,
}) {
  return img.adjustColor(
    cloneImage(source),
    hue: hue,
    saturation: saturation,
  );
}

img.Image applyLevels(
  img.Image source, {
  required int inputBlack,
  required int inputWhite,
  required double gamma,
}) {
  final copy = cloneImage(source);
  final black = inputBlack.clamp(0, 254);
  final white = inputWhite.clamp(black + 1, 255);
  final range = white - black;

  for (final frame in copy.frames) {
    for (final p in frame) {
      p
        ..r = _mapLevelChannel(p.r, black, range)
        ..g = _mapLevelChannel(p.g, black, range)
        ..b = _mapLevelChannel(p.b, black, range);
    }
  }

  return img.gamma(copy, gamma: gamma.clamp(0.1, 5.0));
}

int _mapLevelChannel(num value, int black, int range) {
  return (((value - black) / range) * 255).clamp(0, 255).round();
}

img.Image applyCurves(
  img.Image source, {
  required double gamma,
}) {
  return img.gamma(cloneImage(source), gamma: gamma.clamp(0.1, 5.0));
}

img.Image applyPosterize(
  img.Image source, {
  required int levels,
}) {
  return img.quantize(
    cloneImage(source),
    numberOfColors: levels.clamp(2, 256),
  );
}

/// UI brightness/contrast sliders use 0-200 where 100 is neutral.
double uiBrightnessToFilter(int value) => (value / 100).clamp(0.0, 2.0);

double uiContrastToFilter(int value) => (value / 100).clamp(0.0, 2.0);

double uiSaturationToFilter(int value) => (value / 100).clamp(0.0, 2.0);
