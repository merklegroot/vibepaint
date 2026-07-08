import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/color_picker_math.dart';

void main() {
  test('colorToHexRgba encodes opaque color', () {
    const color = Color(0xFFE9B5A3FF);
    expect(colorToHexRgba(color), 'E9B5A3FF');
  });

  test('colorFromHexRgba parses 8-digit hex', () {
    expect(
      colorFromHexRgba('E9B5A3FF'),
      const Color(0xFFE9B5A3FF),
    );
  });

  test('colorFromHexRgba accepts 6-digit hex as opaque', () {
    expect(
      colorFromHexRgba('#E9B5A3'),
      const Color(0xFFE9B5A3FF),
    );
  });

  test('colorFromHexRgba rejects invalid input', () {
    expect(colorFromHexRgba('ZZZZZZ'), isNull);
    expect(colorFromHexRgba('12345'), isNull);
  });
}
