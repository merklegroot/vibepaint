import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/studio_brush_preset.dart';
import 'package:vibepaint/utils/studio_brush_renderer.dart';

void main() {
  test('kStudioBrushPresets includes five distinct brushes', () {
    expect(kStudioBrushPresets.length, 5);
    expect(
      kStudioBrushPresets.map((preset) => preset.id).toSet().length,
      5,
    );
  });

  test('soft airbrush is softer than smooth marker at the same pressure', () {
    const pressure = 0.7;
    const baseAlpha = 1.0;
    const brushSize = 12.0;

    final smoothRadius = studioBrushRadiusForSettings(
      brushSize,
      pressure,
      StudioBrushSettings.smoothMarker,
    );
    final softRadius = studioBrushRadiusForSettings(
      brushSize,
      pressure,
      StudioBrushSettings.softAirbrush,
    );
    final smoothOpacity = studioBrushOpacityForSettings(
      baseAlpha,
      pressure,
      StudioBrushSettings.smoothMarker,
    );
    final softOpacity = studioBrushOpacityForSettings(
      baseAlpha,
      pressure,
      StudioBrushSettings.softAirbrush,
    );

    expect(softRadius, greaterThan(smoothRadius));
    expect(softOpacity, lessThan(smoothOpacity));
  });

  test('tapered ink narrows more at low pressure', () {
    const brushSize = 12.0;

    final inkRadius = studioBrushRadiusForSettings(
      brushSize,
      0.2,
      StudioBrushSettings.taperedInk,
    );
    final markerRadius = studioBrushRadiusForSettings(
      brushSize,
      0.2,
      StudioBrushSettings.smoothMarker,
    );

    expect(inkRadius, lessThan(markerRadius));
  });
}
