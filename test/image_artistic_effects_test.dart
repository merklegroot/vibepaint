import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_artistic_effects.dart';

void main() {
  test('inkSketch returns image with same dimensions', () {
    final source = img.Image(width: 4, height: 4, numChannels: 4);
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 4; x++) {
        source.setPixelRgba(x, y, 120, 80, 40, 255);
      }
    }

    final result = inkSketch(source, amount: 100);

    expect(result.width, 4);
    expect(result.height, 4);
  });

  test('oilPainting reduces distinct colors', () {
    final source = img.Image(width: 8, height: 8, numChannels: 4);
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        source.setPixelRgba(x, y, x * 30, y * 30, (x + y) * 10, 255);
      }
    }

    final result = oilPainting(source, amount: 100, brushSize: 10);
    final unique = <int>{};
    for (final pixel in result) {
      unique.add(pixel.r);
    }

    expect(unique.length, lessThan(64));
  });
}
