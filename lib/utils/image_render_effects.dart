import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_adjustments.dart';
import 'package:vibepaint/utils/image_effect_helpers.dart';

img.Image cloudsEffect(
  img.Image source, {
  required double scale,
  required double power,
  required int seed,
  required Color primaryColor,
  required Color secondaryColor,
}) {
  final result = cloneImage(source);
  final w = source.width;
  final h = source.height;
  final noiseScale = (0.004 + normalizedAmount(scale) * 0.02) * (200 / math.max(w, h));
  final powerFactor = 0.5 + normalizedAmount(power) * 2.5;
  final c1 = flutterColorToImage(primaryColor);
  final c2 = flutterColorToImage(secondaryColor);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final n = math.pow(fbm(x * noiseScale, y * noiseScale, seed), powerFactor)
          .clamp(0.0, 1.0);
      final r = (c1.r + (c2.r - c1.r) * n).round().clamp(0, 255);
      final g = (c1.g + (c2.g - c1.g) * n).round().clamp(0, 255);
      final b = (c1.b + (c2.b - c1.b) * n).round().clamp(0, 255);
      result.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return result;
}

img.Image juliaFractalEffect(
  img.Image source, {
  required double factor,
  required double quality,
  required double zoom,
  required Color primaryColor,
  required Color secondaryColor,
}) {
  return _renderFractal(
    source,
    factor: factor,
    quality: quality,
    zoom: zoom,
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    julia: true,
    invert: false,
  );
}

img.Image mandelbrotFractalEffect(
  img.Image source, {
  required double factor,
  required double quality,
  required double zoom,
  required Color primaryColor,
  required Color secondaryColor,
  bool invert = false,
}) {
  return _renderFractal(
    source,
    factor: factor,
    quality: quality,
    zoom: zoom,
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    julia: false,
    invert: invert,
  );
}

img.Image _renderFractal(
  img.Image source, {
  required double factor,
  required double quality,
  required double zoom,
  required Color primaryColor,
  required Color secondaryColor,
  required bool julia,
  required bool invert,
}) {
  final result = cloneImage(source);
  final w = source.width;
  final h = source.height;
  final maxIter = (8 + normalizedAmount(quality) * 64).round();
  final sat = 0.5 + normalizedAmount(factor) * 2.5;
  final zoomFactor = math.pow(2, (normalizedAmount(zoom) - 0.5) * 4);
  final c1 = flutterColorToImage(primaryColor);
  final c2 = flutterColorToImage(secondaryColor);

  const juliaC = [0.285, 0.01];

  for (var py = 0; py < h; py++) {
    for (var px = 0; px < w; px++) {
      final x0 = (px / w - 0.5) * 3 / zoomFactor;
      final y0 = (py / h - 0.5) * 3 / zoomFactor;

      double zx;
      double zy;
      double cx;
      double cy;

      if (julia) {
        zx = x0;
        zy = y0;
        cx = juliaC[0];
        cy = juliaC[1];
      } else {
        zx = 0;
        zy = 0;
        cx = x0 - 0.5;
        cy = y0;
      }

      var iteration = 0;
      while (zx * zx + zy * zy < 4 && iteration < maxIter) {
        final xtemp = zx * zx - zy * zy + cx;
        zy = 2 * zx * zy + cy;
        zx = xtemp;
        iteration++;
      }

      if (invert) {
        iteration = maxIter - iteration;
      }

      final color = fractalColor(iteration, maxIter, c1, c2, sat);
      result.setPixel(px, py, color);
    }
  }
  return result;
}
