enum PaintTool {
  brush,
  line,
  rectangle,
  eraser,
}

extension PaintToolLabel on PaintTool {
  String get label => switch (this) {
        PaintTool.brush => 'Brush',
        PaintTool.line => 'Line',
        PaintTool.rectangle => 'Rectangle',
        PaintTool.eraser => 'Eraser',
      };

  bool get isFreehand => this == PaintTool.brush || this == PaintTool.eraser;

  bool get isDragShape =>
      this == PaintTool.line || this == PaintTool.rectangle;
}
