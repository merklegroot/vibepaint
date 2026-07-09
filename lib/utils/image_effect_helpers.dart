import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

double normalizedAmount(double value) => (value / 100).clamp(0.0, 1.0);

img.Color flutterColorToImage(Color color) {
  return img.ColorRgba8(
    (color.r * 255).round().clamp(0, 255),
    (color.g * 255).round().clamp(0, 255),
    (color.b * 255).round().clamp(0, 255),
    (color.a * 255).round().clamp(0, 255),
  );
}

img.Color sampleBilinear(
  img.Image source,
  double x,
  double y, {
  img.Interpolation interpolation = img.Interpolation.linear,
}) {
  return source.getPixelInterpolate(x, y, interpolation: interpolation);
}

List<num> rotatedEmbossKernel(double angleDegrees) {
  final radians = angleDegrees * math.pi / 180;
  final cos = math.cos(radians);
  final sin = math.sin(radians);
  const light = 1.5;
  const dark = -1.5;

  final lx = cos * light;
  final ly = sin * light;
  final dx = -cos * dark;
  final dy = -sin * dark;

  return [
    0, 0, 0,
    lx, 0, dx,
    ly, 0, dy,
  ];
}

double fractalNoise(int x, int y, int seed) {
  final n = math.sin(x * 127.1 + y * 311.7 + seed * 41.17) * 43758.5453;
  return n - n.floor();
}

double smoothNoise(double x, double y, int seed) {
  final x0 = x.floor();
  final y0 = y.floor();
  final fx = x - x0;
  final fy = y - y0;
  final ux = fx * fx * (3 - 2 * fx);
  final uy = fy * fy * (3 - 2 * fy);

  final a = fractalNoise(x0.toInt(), y0.toInt(), seed);
  final b = fractalNoise(x0.toInt() + 1, y0.toInt(), seed);
  final c = fractalNoise(x0.toInt(), y0.toInt() + 1, seed);
  final d = fractalNoise(x0.toInt() + 1, y0.toInt() + 1, seed);

  return (a * (1 - ux) + b * ux) * (1 - uy) + (c * (1 - ux) + d * ux) * uy;
}

double fbm(double x, double y, int seed, {int octaves = 4}) {
  var value = 0.0;
  var amplitude = 0.5;
  var frequency = 1.0;
  for (var i = 0; i < octaves; i++) {
    value += amplitude * smoothNoise(x * frequency, y * frequency, seed + i);
    amplitude *= 0.5;
    frequency *= 2;
  }
  return value;
}

img.ColorRgba8 fractalColor(
  int iterations,
  int maxIterations,
  img.Color color1,
  img.Color color2,
  double factor,
) {
  final t = (iterations / maxIterations).clamp(0.0, 1.0);
  final sat = factor.clamp(0.1, 4.0);
  final r = (color1.r + (color2.r - color1.r) * t) * sat;
  final g = (color1.g + (color2.g - color1.g) * t) * sat;
  final b = (color1.b + (color2.b - color1.b) * t) * sat;
  return img.ColorRgba8(
    r.round().clamp(0, 255),
    g.round().clamp(0, 255),
    b.round().clamp(0, 255),
    255,
  );
}
