import 'package:flutter/material.dart';

enum ColorWheelMode {
  hueSaturation,
  saturationValue,
}

String colorToHexRgba(Color color) {
  final value = color.toARGB32();
  return value.toRadixString(16).padLeft(8, '0').toUpperCase();
}

Color? colorFromHexRgba(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 6) {
    hex = '${hex}FF';
  }
  if (hex.length != 8) {
    return null;
  }

  final value = int.tryParse(hex, radix: 16);
  if (value == null) {
    return null;
  }

  return Color(value);
}

int clampChannel(int value) => value.clamp(0, 255);

double clampUnit(double value) => value.clamp(0.0, 1.0);

HSVColor hsvFromChannels({
  required double hue,
  required double saturation,
  required double value,
  double alpha = 1,
}) {
  return HSVColor.fromAHSV(
    clampUnit(alpha),
    hue % 360,
    clampUnit(saturation),
    clampUnit(value),
  );
}
