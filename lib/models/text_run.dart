import 'package:flutter/painting.dart';

class TextRun {
  const TextRun({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    this.fontFamily,
    this.bold = false,
    this.italic = false,
  });

  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final String? fontFamily;
  final bool bold;
  final bool italic;

  bool get isEmpty => text.trim().isEmpty;

  TextStyle get textStyle => TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: 1.2,
      );

  TextPainter createPainter({double maxWidth = double.infinity}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter;
  }

  Rect bounds({double maxWidth = double.infinity}) {
    final painter = createPainter(maxWidth: maxWidth);
    try {
      return position &
          Size(painter.width.clamp(1, double.infinity), painter.height);
    } finally {
      painter.dispose();
    }
  }

  TextRun copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
    String? fontFamily,
    bool? bold,
    bool? italic,
  }) {
    return TextRun(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
    );
  }
}
