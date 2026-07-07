enum PaintTool {
  brush,
  line,
  eraser,
}

extension PaintToolLabel on PaintTool {
  String get label => switch (this) {
        PaintTool.brush => 'Brush',
        PaintTool.line => 'Line',
        PaintTool.eraser => 'Eraser',
      };

  bool get isFreehand => this == PaintTool.brush || this == PaintTool.eraser;
}
