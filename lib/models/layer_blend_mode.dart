import 'dart:ui';

enum LayerBlendMode {
  normal,
  multiply,
  screen,
  overlay,
  darken,
  lighten,
}

extension LayerBlendModeDetails on LayerBlendMode {
  String get label => switch (this) {
        LayerBlendMode.normal => 'Normal',
        LayerBlendMode.multiply => 'Multiply',
        LayerBlendMode.screen => 'Screen',
        LayerBlendMode.overlay => 'Overlay',
        LayerBlendMode.darken => 'Darken',
        LayerBlendMode.lighten => 'Lighten',
      };

  BlendMode get paintBlendMode => switch (this) {
        LayerBlendMode.normal => BlendMode.srcOver,
        LayerBlendMode.multiply => BlendMode.multiply,
        LayerBlendMode.screen => BlendMode.screen,
        LayerBlendMode.overlay => BlendMode.overlay,
        LayerBlendMode.darken => BlendMode.darken,
        LayerBlendMode.lighten => BlendMode.lighten,
      };
}
