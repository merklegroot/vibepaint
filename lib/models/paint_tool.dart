enum PaintTool {
  brush,
  pencil,
  line,
  rectangle,
  ellipse,
  eraser,
  fillBucket,
  text,
  magicWand,
  eyedropper,
  rectSelect,
  ellipseSelect,
  lassoSelect,
}

extension PaintToolLabel on PaintTool {
  String get label => switch (this) {
        PaintTool.brush => 'Brush',
        PaintTool.pencil => 'Pencil',
        PaintTool.line => 'Line',
        PaintTool.rectangle => 'Rectangle',
        PaintTool.ellipse => 'Ellipse',
        PaintTool.eraser => 'Eraser',
        PaintTool.fillBucket => 'Paint Bucket',
        PaintTool.text => 'Text',
        PaintTool.magicWand => 'Magic Wand',
        PaintTool.eyedropper => 'Color Picker',
        PaintTool.rectSelect => 'Rectangle Select',
        PaintTool.ellipseSelect => 'Ellipse Select',
        PaintTool.lassoSelect => 'Lasso Select',
      };

  bool get isFreehand =>
      this == PaintTool.brush ||
      this == PaintTool.pencil ||
      this == PaintTool.eraser;

  bool get isDragShape =>
      this == PaintTool.line ||
      this == PaintTool.rectangle ||
      this == PaintTool.ellipse;

  bool get isEyedropper => this == PaintTool.eyedropper;

  bool get isClickTool =>
      this == PaintTool.eyedropper ||
      this == PaintTool.fillBucket ||
      this == PaintTool.magicWand ||
      this == PaintTool.text;

  bool get isSelectionTool =>
      this == PaintTool.rectSelect ||
      this == PaintTool.ellipseSelect ||
      this == PaintTool.lassoSelect;

  bool get isBoxSelectionTool =>
      this == PaintTool.rectSelect || this == PaintTool.ellipseSelect;

  bool get supportsFillStyle =>
      this == PaintTool.rectangle || this == PaintTool.ellipse;

  bool get isTextTool => this == PaintTool.text;
}
