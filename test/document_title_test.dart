import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/utils/app_version.dart';
import 'package:vibepaint/utils/document_title.dart';

void main() {
  tearDown(() {
    debugSetAppVersion(null);
  });

  test('formats clean untitled window title with version', () {
    debugSetAppVersion('1.0.2');
    expect(
      formatDocumentTitle(documentPath: null, isDirty: false),
      'Untitled - VibePaint 1.0.2',
    );
  });

  test('formats title without version when unknown', () {
    debugSetAppVersion(null);
    expect(
      formatDocumentTitle(documentPath: null, isDirty: false),
      'Untitled - VibePaint',
    );
  });

  test('formats dirty document with asterisk prefix', () {
    debugSetAppVersion('1.0.2');
    expect(
      formatDocumentTitle(
        documentPath: '/tmp/sketch.png',
        isDirty: true,
      ),
      '*sketch.png - VibePaint 1.0.2',
    );
  });

  test('formats saved document without asterisk', () {
    debugSetAppVersion('1.0.2');
    expect(
      formatDocumentTitle(
        documentPath: '/tmp/sketch.png',
        isDirty: false,
      ),
      'sketch.png - VibePaint 1.0.2',
    );
  });
}
