import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_color_effects.dart';

void main() {
  test('ditheringEffect preserves image dimensions', () {
    final source = img.Image(width: 8, height: 8, numChannels: 4);
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        source.setPixelRgba(x, y, x * 30, y * 30, 200, 255);
      }
    }

    final result = ditheringEffect(
      source,
      colorLevels: 8,
      kernel: img.DitherKernel.floydSteinberg,
    );

    expect(result.width, 8);
    expect(result.height, 8);
  });

  test('ditheringEffect with none kernel quantizes colors', () {
    final source = img.Image(width: 2, height: 2, numChannels: 4);
    source.setPixelRgba(0, 0, 100, 150, 200, 255);
    source.setPixelRgba(1, 0, 110, 160, 210, 255);
    source.setPixelRgba(0, 1, 120, 170, 220, 255);
    source.setPixelRgba(1, 1, 130, 180, 230, 255);

    final result = ditheringEffect(
      source,
      colorLevels: 2,
      kernel: img.DitherKernel.none,
    );

    expect(result.width, 2);
    expect(result.height, 2);
  });
}
