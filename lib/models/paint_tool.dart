enum PaintTool {
  brush,
  line,
  rectangle,
  ellipse,
  eraser,
  rectSelect,
  ellipseSelect,
}

extension PaintToolLabel on PaintTool {
  String get label => switch (this) {
        PaintTool.brush => 'Brush',
        PaintTool.line => 'Line',
        PaintTool.rectangle => 'Rectangle',
        PaintTool.ellipse => 'Ellipse',
        PaintTool.eraser => 'Eraser',
        PaintTool.rectSelect => 'Rectangle Select',
        PaintTool.ellipseSelect => 'Ellipse Select',
      };

  bool get isFreehand => this == PaintTool.brush || this == PaintTool.eraser;

  bool get isDragShape =>
      this == PaintTool.line ||
      this == PaintTool.rectangle ||
      this == PaintTool.ellipse;

  bool get isSelectionTool =>
      this == PaintTool.rectSelect || this == PaintTool.ellipseSelect;

  bool get supportsFillStyle =>
      this == PaintTool.rectangle || this == PaintTool.ellipse;
}
