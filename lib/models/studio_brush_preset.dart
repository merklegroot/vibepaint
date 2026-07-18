import 'package:flutter/material.dart';

enum StudioBrushPresetId {
  smoothMarker,
  softAirbrush,
  taperedInk,
  dryMarker,
  flatChalk,
}

/// Tunable parameters for the studio brush engine.
class StudioBrushSettings {
  const StudioBrushSettings({
    required this.responsiveness,
    required this.spacingFactor,
    required this.initialTouchPressure,
    required this.startRampFactor,
    required this.minRadiusFactor,
    required this.maxRadiusFactor,
    required this.minOpacityFactor,
    required this.maxOpacityFactor,
    required this.blurFactor,
    required this.coreRadiusFactor,
    required this.coreAlphaFactor,
    required this.speedSlowness,
    required this.velocityRestPressure,
    required this.velocityMinPressure,
    required this.startTaperLengthFactor,
    required this.endTaperLengthFactor,
    required this.taperTipSize,
    required this.taperTipOpacity,
    this.scatterAmount = 0,
    this.scatterPasses = 1,
  });

  final double responsiveness;
  final double spacingFactor;
  final double initialTouchPressure;
  final double startRampFactor;
  final double minRadiusFactor;
  final double maxRadiusFactor;
  final double minOpacityFactor;
  final double maxOpacityFactor;
  final double blurFactor;
  final double coreRadiusFactor;
  final double coreAlphaFactor;
  final double speedSlowness;
  final double velocityRestPressure;
  final double velocityMinPressure;
  final double startTaperLengthFactor;
  final double endTaperLengthFactor;
  final double taperTipSize;
  final double taperTipOpacity;
  final double scatterAmount;
  final int scatterPasses;

  static const smoothMarker = StudioBrushSettings(
    responsiveness: 0.55,
    spacingFactor: 0.14,
    initialTouchPressure: 0.26,
    startRampFactor: 0.16,
    minRadiusFactor: 0.22,
    maxRadiusFactor: 1.0,
    minOpacityFactor: 0.32,
    maxOpacityFactor: 1.0,
    blurFactor: 0.45,
    coreRadiusFactor: 0.55,
    coreAlphaFactor: 0.65,
    speedSlowness: 0.05,
    velocityRestPressure: 0.58,
    velocityMinPressure: 0.08,
    startTaperLengthFactor: 1.6,
    endTaperLengthFactor: 1.3,
    taperTipSize: 0.12,
    taperTipOpacity: 0.35,
  );

  static const softAirbrush = StudioBrushSettings(
    responsiveness: 0.5,
    spacingFactor: 0.18,
    initialTouchPressure: 0.18,
    startRampFactor: 0.14,
    minRadiusFactor: 0.35,
    maxRadiusFactor: 1.05,
    minOpacityFactor: 0.18,
    maxOpacityFactor: 0.82,
    blurFactor: 0.72,
    coreRadiusFactor: 0.28,
    coreAlphaFactor: 0.4,
    speedSlowness: 0.07,
    velocityRestPressure: 0.52,
    velocityMinPressure: 0.12,
    startTaperLengthFactor: 1.4,
    endTaperLengthFactor: 1.2,
    taperTipSize: 0.18,
    taperTipOpacity: 0.45,
  );

  static const taperedInk = StudioBrushSettings(
    responsiveness: 0.42,
    spacingFactor: 0.11,
    initialTouchPressure: 0.2,
    startRampFactor: 0.12,
    minRadiusFactor: 0.12,
    maxRadiusFactor: 0.92,
    minOpacityFactor: 0.28,
    maxOpacityFactor: 0.95,
    blurFactor: 0.32,
    coreRadiusFactor: 0.42,
    coreAlphaFactor: 0.75,
    speedSlowness: 0.04,
    velocityRestPressure: 0.54,
    velocityMinPressure: 0.04,
    startTaperLengthFactor: 2.2,
    endTaperLengthFactor: 2.0,
    taperTipSize: 0.04,
    taperTipOpacity: 0.15,
  );

  static const dryMarker = StudioBrushSettings(
    responsiveness: 0.35,
    spacingFactor: 0.1,
    initialTouchPressure: 0.24,
    startRampFactor: 0.15,
    minRadiusFactor: 0.2,
    maxRadiusFactor: 0.95,
    minOpacityFactor: 0.26,
    maxOpacityFactor: 0.88,
    blurFactor: 0.22,
    coreRadiusFactor: 0.72,
    coreAlphaFactor: 0.55,
    speedSlowness: 0.06,
    velocityRestPressure: 0.6,
    velocityMinPressure: 0.18,
    startTaperLengthFactor: 1.2,
    endTaperLengthFactor: 1.0,
    taperTipSize: 0.2,
    taperTipOpacity: 0.5,
    scatterAmount: 0.38,
    scatterPasses: 3,
  );

  static const flatChalk = StudioBrushSettings(
    responsiveness: 0.3,
    spacingFactor: 0.16,
    initialTouchPressure: 0.3,
    startRampFactor: 0.18,
    minRadiusFactor: 0.28,
    maxRadiusFactor: 0.98,
    minOpacityFactor: 0.34,
    maxOpacityFactor: 0.92,
    blurFactor: 0.52,
    coreRadiusFactor: 0.78,
    coreAlphaFactor: 0.58,
    speedSlowness: 0.065,
    velocityRestPressure: 0.62,
    velocityMinPressure: 0.14,
    startTaperLengthFactor: 1.3,
    endTaperLengthFactor: 1.1,
    taperTipSize: 0.16,
    taperTipOpacity: 0.4,
    scatterAmount: 0.16,
    scatterPasses: 2,
  );
}

class StudioBrushPreset {
  const StudioBrushPreset({
    required this.id,
    required this.label,
    required this.category,
    required this.settings,
    required this.previewIcon,
  });

  final StudioBrushPresetId id;
  final String label;
  final String category;
  final StudioBrushSettings settings;
  final IconData previewIcon;
}

const kStudioBrushPresets = <StudioBrushPreset>[
  StudioBrushPreset(
    id: StudioBrushPresetId.smoothMarker,
    label: 'Smooth Marker',
    category: 'Markers',
    settings: StudioBrushSettings.smoothMarker,
    previewIcon: Icons.brush,
  ),
  StudioBrushPreset(
    id: StudioBrushPresetId.softAirbrush,
    label: 'Soft Airbrush',
    category: 'Markers',
    settings: StudioBrushSettings.softAirbrush,
    previewIcon: Icons.blur_on,
  ),
  StudioBrushPreset(
    id: StudioBrushPresetId.taperedInk,
    label: 'Tapered Ink',
    category: 'Inks',
    settings: StudioBrushSettings.taperedInk,
    previewIcon: Icons.gesture,
  ),
  StudioBrushPreset(
    id: StudioBrushPresetId.dryMarker,
    label: 'Dry Marker',
    category: 'Markers',
    settings: StudioBrushSettings.dryMarker,
    previewIcon: Icons.grain,
  ),
  StudioBrushPreset(
    id: StudioBrushPresetId.flatChalk,
    label: 'Flat Chalk',
    category: 'Pastels',
    settings: StudioBrushSettings.flatChalk,
    previewIcon: Icons.texture,
  ),
];

StudioBrushPreset studioBrushPresetById(StudioBrushPresetId id) {
  for (final preset in kStudioBrushPresets) {
    if (preset.id == id) {
      return preset;
    }
  }
  return kStudioBrushPresets.first;
}

StudioBrushSettings studioBrushSettingsForId(StudioBrushPresetId? id) {
  if (id == null) {
    return StudioBrushSettings.smoothMarker;
  }
  return studioBrushPresetById(id).settings;
}
