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
    this.underline = false,
    this.align = TextAlign.left,
  });

  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final String? fontFamily;
  final bool bold;
  final bool italic;
  final bool underline;
  final TextAlign align;

  bool get isEmpty => text.trim().isEmpty;

  TextStyle get textStyle => TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        decoration: underline ? TextDecoration.underline : TextDecoration.none,
        decorationColor: color,
        height: 1.2,
      );

  TextPainter createPainter({double? maxWidth}) {
    final width = maxWidth ??
        (align == TextAlign.left ? double.infinity : fontSize * 18);
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    return painter;
  }

  Rect bounds({double? maxWidth}) {
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
    bool clearFontFamily = false,
    bool? bold,
    bool? italic,
    bool? underline,
    TextAlign? align,
  }) {
    return TextRun(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: clearFontFamily ? null : (fontFamily ?? this.fontFamily),
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      align: align ?? this.align,
    );
  }
}

/// Common desktop fonts with fallbacks across platforms.
abstract final class PaintTextFonts {
  static const systemLabel = 'System';

  static const options = <({String label, String? family})>[
    (label: systemLabel, family: null),
    (label: 'Arial', family: 'Arial'),
    (label: 'Courier New', family: 'Courier New'),
    (label: 'Georgia', family: 'Georgia'),
    (label: 'Helvetica', family: 'Helvetica'),
    (label: 'Times New Roman', family: 'Times New Roman'),
    (label: 'Trebuchet MS', family: 'Trebuchet MS'),
    (label: 'Verdana', family: 'Verdana'),
  ];

  static const sizes = <double>[
    8,
    9,
    10,
    11,
    12,
    14,
    16,
    18,
    20,
    24,
    28,
    32,
    36,
    48,
    64,
    72,
  ];
}
