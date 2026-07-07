import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/main.dart';

void main() {
  testWidgets('VibePaint renders the canvas workspace', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const VibePaintApp());

    expect(find.text('Colors'), findsOneWidget);
    expect(find.textContaining('Drag on the canvas to paint'), findsOneWidget);
  });
}
