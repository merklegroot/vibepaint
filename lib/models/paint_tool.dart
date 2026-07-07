enum PaintTool {
  brush,
  line,
  rectangle,
  ellipse,
  eraser,
}

extension PaintToolLabel on PaintTool {
  String get label => switch (this) {
        PaintTool.brush => 'Brush',
        PaintTool.line => 'Line',
        PaintTool.rectangle => 'Rectangle',
        PaintTool.ellipse => 'Ellipse',
        PaintTool.eraser => 'Eraser',
      };

  bool get isFreehand => this == PaintTool.brush || this == PaintTool.eraser;

  bool get isDragShape =>
      this == PaintTool.line ||
      this == PaintTool.rectangle ||
      this == PaintTool.ellipse;
}
