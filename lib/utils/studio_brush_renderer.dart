import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/studio_brush_preset.dart';
import 'package:vibepaint/utils/studio_brush.dart';

double studioBrushRadiusForSettings(
  double brushSize,
  double pressure,
  StudioBrushSettings settings,
) {
  return brushSize *
      (settings.minRadiusFactor +
          (settings.maxRadiusFactor - settings.minRadiusFactor) * pressure) /
      2;
}

double studioBrushOpacityForSettings(
  double baseAlpha,
  double pressure,
  StudioBrushSettings settings,
) {
  return (baseAlpha *
          (settings.minOpacityFactor +
              (settings.maxOpacityFactor - settings.minOpacityFactor) *
                  pressure))
      .clamp(0.05, 1);
}

Offset _scatterOffset(Offset point, int pass, double amount, double radius) {
  final seed = math.sin(
        point.dx * 12.9898 + point.dy * 78.233 + pass * 43.758,
      ) *
      43758.5453;
  final angle = (seed - seed.floor()) * math.pi * 2;
  final distance = amount * radius * (0.45 + (pass % 3) * 0.18);
  return Offset(math.cos(angle), math.sin(angle)) * distance;
}

void paintStudioBrushStrokeRange(
  Canvas canvas,
  Stroke stroke, {
  required int startIndex,
  required int endIndex,
  StudioBrushStrokePhase phase = StudioBrushStrokePhase.committed,
}) {
  if (stroke.points.isEmpty || startIndex >= endIndex) {
    return;
  }

  final settings = studioBrushSettingsForId(stroke.studioBrushPreset);
  final baseAlpha =
      (stroke.color.a * stroke.brushOpacity).clamp(0.0, 1.0).toDouble();
  final blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;
  final clampedStart = startIndex.clamp(0, stroke.points.length);
  final clampedEnd = endIndex.clamp(clampedStart, stroke.points.length);
  final arcLengths = studioBrushArcLengths(stroke.points);
  final totalLength = arcLengths.isEmpty ? 0.0 : arcLengths.last;

  for (var i = clampedStart; i < clampedEnd; i++) {
    final velocityPressure =
        i < stroke.pressures.length ? stroke.pressures[i] : 1.0;
    final distanceFromStart = arcLengths[i];
    final distanceFromEnd = totalLength - distanceFromStart;
    final sizeMul = studioBrushTaperSizeMultiplier(
      distanceFromStart: distanceFromStart,
      distanceFromEnd: distanceFromEnd,
      brushSize: stroke.brushSize,
      settings: settings,
      phase: phase,
    );
    final opacityMul = studioBrushTaperOpacityMultiplier(
      distanceFromStart: distanceFromStart,
      distanceFromEnd: distanceFromEnd,
      brushSize: stroke.brushSize,
      settings: settings,
      phase: phase,
    );
    paintStudioBrushStamp(
      canvas,
      point: stroke.points[i],
      pressure: (velocityPressure * sizeMul).clamp(0.04, 1.0),
      brushSize: stroke.brushSize,
      color: stroke.color,
      baseAlpha: baseAlpha * opacityMul,
      settings: settings,
      blendMode: blendMode,
    );
  }
}

void paintStudioBrushStamp(
  Canvas canvas, {
  required Offset point,
  required double pressure,
  required double brushSize,
  required Color color,
  required double baseAlpha,
  required StudioBrushSettings settings,
  required BlendMode blendMode,
}) {
  void drawStamp(Offset center, double stampPressure, {double alphaScale = 1}) {
    final radius = studioBrushRadiusForSettings(
      brushSize,
      stampPressure,
      settings,
    );
    if (radius <= 0) {
      return;
    }

    final alpha = studioBrushOpacityForSettings(
      baseAlpha * alphaScale,
      stampPressure,
      settings,
    );
    final stampColor = blendMode == BlendMode.clear
        ? Colors.transparent
        : color.withValues(alpha: alpha);

    final soft = Paint()
      ..color = stampColor
      ..blendMode = blendMode
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        radius * settings.blurFactor,
      );
    canvas.drawCircle(center, radius, soft);

    final core = Paint()
      ..color = stampColor.withValues(
        alpha: (alpha * settings.coreAlphaFactor).clamp(0.04, 1.0).toDouble(),
      )
      ..blendMode = blendMode;
    canvas.drawCircle(center, radius * settings.coreRadiusFactor, core);
  }

  drawStamp(point, pressure);

  if (settings.scatterAmount <= 0 || settings.scatterPasses <= 1) {
    return;
  }

  final radius = studioBrushRadiusForSettings(brushSize, pressure, settings);
  for (var pass = 1; pass < settings.scatterPasses; pass++) {
    drawStamp(
      point + _scatterOffset(point, pass, settings.scatterAmount, radius),
      pressure * (0.72 - pass * 0.08),
      alphaScale: 0.62,
    );
  }
}

void paintStudioBrushPreviewStroke(
  Canvas canvas,
  Size size,
  StudioBrushSettings settings, {
  Color color = Colors.white,
}) {
  const brushSize = 14.0;
  const baseAlpha = 0.95;
  final path = _previewSamplePoints(size);

  for (var i = 0; i < path.length; i++) {
    final t = i / (path.length - 1);
    final pressure = 0.22 + math.sin(t * math.pi) * 0.62;
    paintStudioBrushStamp(
      canvas,
      point: path[i],
      pressure: pressure,
      brushSize: brushSize,
      color: color,
      baseAlpha: baseAlpha,
      settings: settings,
      blendMode: BlendMode.srcOver,
    );

    if (i == 0) {
      continue;
    }

    final maxStep = brushSize * settings.spacingFactor;
    final steps = studioBrushSegmentPoints(
      from: path[i - 1],
      to: path[i],
      maxStep: maxStep,
    );
    for (var j = 0; j < steps.length; j++) {
      final stepT = steps.length == 1 ? 1 : (j + 1) / steps.length;
      final stepPressure =
          pressure * (0.85 + stepT * 0.15) * (0.9 + stepT * 0.1);
      paintStudioBrushStamp(
        canvas,
        point: steps[j],
        pressure: stepPressure.clamp(0.12, 1),
        brushSize: brushSize,
        color: color,
        baseAlpha: baseAlpha,
        settings: settings,
        blendMode: BlendMode.srcOver,
      );
    }
  }
}

List<Offset> _previewSamplePoints(Size size) {
  final midY = size.height * 0.62;
  return [
    for (var i = 0; i <= 24; i++)
      Offset(size.width * (0.04 + i / 24 * 0.92), midY - math.sin(i / 4) * 4),
  ];
}
