import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_adjustments.dart';

void main() {
  test('invertColors inverts pixel values', () {
    final source = img.Image(width: 1, height: 1, numChannels: 4);
    source.setPixelRgba(0, 0, 100, 150, 200, 255);

    final result = invertColors(source);

    expect(result.getPixel(0, 0).r, 155);
    expect(result.getPixel(0, 0).g, 105);
    expect(result.getPixel(0, 0).b, 55);
  });

  test('applyLevels stretches input range', () {
    final source = img.Image(width: 1, height: 1, numChannels: 4);
    source.setPixelRgba(0, 0, 64, 128, 192, 255);

    final result = applyLevels(
      source,
      inputBlack: 0,
      inputWhite: 255,
      gamma: 1,
    );

    expect(result.getPixel(0, 0).r, 64);
    expect(result.getPixel(0, 0).g, 128);
    expect(result.getPixel(0, 0).b, 192);
  });
}
