enum PaintTool {
  brush,
  eraser,
}

extension PaintToolLabel on PaintTool {
  String get label => switch (this) {
        PaintTool.brush => 'Brush',
        PaintTool.eraser => 'Eraser',
      };
}
