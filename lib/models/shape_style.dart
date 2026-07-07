enum ShapeStyle {
  outline,
  filled,
  filledOutline,
}

extension ShapeStyleLabel on ShapeStyle {
  String get label => switch (this) {
        ShapeStyle.outline => 'Outline',
        ShapeStyle.filled => 'Filled',
        ShapeStyle.filledOutline => 'Filled + outline',
      };

  bool get drawsFill =>
      this == ShapeStyle.filled || this == ShapeStyle.filledOutline;

  bool get drawsOutline =>
      this == ShapeStyle.outline || this == ShapeStyle.filledOutline;
}
