import 'package:vibepaint/models/layer_blend_mode.dart';

LayerBlendMode layerBlendModeFromOraCompositeOp(String? compositeOp) {
  return switch (compositeOp) {
    'svg:multiply' => LayerBlendMode.multiply,
    'svg:screen' => LayerBlendMode.screen,
    'svg:overlay' => LayerBlendMode.overlay,
    'svg:darken' => LayerBlendMode.darken,
    'svg:lighten' => LayerBlendMode.lighten,
    _ => LayerBlendMode.normal,
  };
}

String oraCompositeOpFromLayerBlendMode(LayerBlendMode blendMode) {
  return switch (blendMode) {
    LayerBlendMode.normal => 'svg:src-over',
    LayerBlendMode.multiply => 'svg:multiply',
    LayerBlendMode.screen => 'svg:screen',
    LayerBlendMode.overlay => 'svg:overlay',
    LayerBlendMode.darken => 'svg:darken',
    LayerBlendMode.lighten => 'svg:lighten',
  };
}

String oraVisibilityAttribute(bool visible) => visible ? 'visible' : 'hidden';

bool layerVisibilityFromOra(String? visibility) {
  return switch (visibility?.toLowerCase()) {
    'hidden' || 'false' || '0' => false,
    _ => true,
  };
}
