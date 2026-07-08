import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/document_title.dart';

void main() {
  test('formats clean untitled window title', () {
    expect(
      formatDocumentTitle(documentPath: null, isDirty: false),
      'Untitled - VibePaint',
    );
  });

  test('formats dirty document with asterisk prefix', () {
    expect(
      formatDocumentTitle(
        documentPath: '/tmp/sketch.png',
        isDirty: true,
      ),
      '*sketch.png - VibePaint',
    );
  });

  test('formats saved document without asterisk', () {
    expect(
      formatDocumentTitle(
        documentPath: '/tmp/sketch.png',
        isDirty: false,
      ),
      'sketch.png - VibePaint',
    );
  });
}
