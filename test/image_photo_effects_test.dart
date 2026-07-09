import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_distort_effects.dart';
import 'package:vibepaint/utils/image_photo_effects.dart';
import 'package:vibepaint/utils/image_stylize_effects.dart';

void main() {
  test('sharpenEffect preserves image dimensions', () {
    final source = img.Image(width: 6, height: 6, numChannels: 4);
    source.setPixelRgba(0, 0, 255, 128, 64, 255);

    final result = sharpenEffect(source, amount: 50);

    expect(result.width, 6);
    expect(result.height, 6);
  });

  test('pixelateEffect reduces detail with larger cells', () {
    final source = img.Image(width: 8, height: 8, numChannels: 4);
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        source.setPixelRgba(x, y, x * 30, y * 30, 128, 255);
      }
    }

    final result = pixelateEffect(source, cellSize: 4);

    expect(result.getPixel(0, 0), result.getPixel(3, 3));
  });

  test('embossEffect preserves image dimensions', () {
    final source = img.Image(width: 4, height: 4, numChannels: 4);
    source.setPixelRgba(1, 1, 200, 100, 50, 255);

    final result = embossEffect(source, angle: 45);

    expect(result.width, 4);
    expect(result.height, 4);
  });
}
