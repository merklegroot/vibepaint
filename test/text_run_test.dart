import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/text_run.dart';

void main() {
  test('TextRun bounds covers painted text', () {
    const run = TextRun(
      text: 'Hello',
      position: Offset(10, 20),
      color: Color(0xFF000000),
      fontSize: 24,
    );

    final bounds = run.bounds();
    expect(bounds.left, 10);
    expect(bounds.top, 20);
    expect(bounds.width, greaterThan(0));
    expect(bounds.height, greaterThan(0));
  });

  test('empty TextRun reports isEmpty', () {
    const run = TextRun(
      text: '   ',
      position: Offset.zero,
      color: Color(0xFF000000),
      fontSize: 16,
    );
    expect(run.isEmpty, isTrue);
  });

  test('copyWith updates style flags', () {
    const run = TextRun(
      text: 'A',
      position: Offset.zero,
      color: Color(0xFF000000),
      fontSize: 16,
    );
    final bold = run.copyWith(bold: true, italic: true);
    expect(bold.bold, isTrue);
    expect(bold.italic, isTrue);
    expect(bold.text, 'A');
  });
}
