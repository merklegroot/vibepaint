import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/image_file_format.dart';

void main() {
  test('normalizeImagePath adds default extension', () {
    expect(
      normalizeImagePath('/tmp/sketch', ImageFileFormat.jpeg),
      '/tmp/sketch.jpg',
    );
  });

  test('normalizeImagePath keeps existing extension', () {
    expect(
      normalizeImagePath('/tmp/sketch.jpeg', ImageFileFormat.jpeg),
      '/tmp/sketch.jpeg',
    );
  });

  test('defaultSaveFileName uses selected format extension', () {
    expect(
      defaultSaveFileName(
        documentPath: '/tmp/sketch.png',
        format: ImageFileFormat.jpeg,
      ),
      'sketch.jpg',
    );
  });
}
