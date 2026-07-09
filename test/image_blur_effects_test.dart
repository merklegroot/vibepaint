import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_blur_effects.dart';

void main() {
  test('gaussianBlurEffect with zero radius returns clone', () {
    final source = img.Image(width: 4, height: 4, numChannels: 4);
    source.setPixelRgba(0, 0, 255, 0, 0, 255);

    final result = gaussianBlurEffect(source, radius: 0);

    expect(result.getPixel(0, 0).r, 255);
  });

  test('motionBlurEffect preserves image dimensions', () {
    final source = img.Image(width: 6, height: 6, numChannels: 4);
    for (var y = 0; y < 6; y++) {
      for (var x = 0; x < 6; x++) {
        source.setPixelRgba(x, y, x * 40, y * 40, 128, 255);
      }
    }

    final result = motionBlurEffect(source, angle: 0, distance: 3);

    expect(result.width, 6);
    expect(result.height, 6);
  });
}
