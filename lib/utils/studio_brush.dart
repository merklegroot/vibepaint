import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';

import 'package:vibepaint/models/studio_brush_preset.dart';

/// Stabilization strength for the studio brush (0 = frozen, 1 = raw input).
const studioBrushResponsiveness = 0.55;

/// Minimum spacing between paint stamps as a fraction of brush size.
const studioBrushSpacingFactor = 0.14;

/// Light pressure for first contact before movement is sampled.
const studioBrushInitialTouchPressure = 0.26;

/// Distance (as a fraction of brush size) needed to ramp from initial touch
/// pressure to velocity-based pressure.
const studioBrushStartRampFactor = 0.16;

/// Log-offset for speed mapping (libmypaint SPEED1 gamma). Compresses the
/// low end so near-zero speed does not dominate thickness.
const studioBrushSpeedGamma = 1.0;

/// Normalized speed ceiling used when mapping log-speed to pressure.
const studioBrushSpeedNormalizedMax = 3.0;

double _studioBrushSmoothstep(double t) {
  final x = t.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// Exponential low-pass filter for pointer speed (libmypaint NORM_SPEED1_SLOW).
double studioBrushFilterSpeed({
  required double rawSpeedPxPerSec,
  required double filteredSpeedPxPerSec,
  required double dtSeconds,
  required double slowness,
}) {
  if (dtSeconds <= 0) {
    return filteredSpeedPxPerSec;
  }

  final tau = slowness.clamp(0.002, 1.0);
  final alpha = 1.0 - math.exp(-dtSeconds / tau);
  return filteredSpeedPxPerSec +
      (rawSpeedPxPerSec - filteredSpeedPxPerSec) * alpha;
}

/// Maps filtered speed to brush pressure using log compression plus a smooth
/// inverse curve: slow/stopped = thicker, fast = thinner.
double studioBrushPressureFromVelocity(
  double filteredSpeedPxPerSec,
  double brushSize, {
  StudioBrushSettings settings = StudioBrushSettings.smoothMarker,
}) {
  final reference = brushSize * 8;
  if (reference <= 0) {
    return settings.velocityRestPressure;
  }

  final normalized =
      (filteredSpeedPxPerSec / reference).clamp(0.0, studioBrushSpeedNormalizedMax);
  final logInput = math.log(studioBrushSpeedGamma + normalized);
  final logAtZero = math.log(studioBrushSpeedGamma);
  final logAtMax = math.log(studioBrushSpeedGamma + studioBrushSpeedNormalizedMax);
  final span = logAtMax - logAtZero;
  final t = span <= 0
      ? 0.0
      : ((logInput - logAtZero) / span).clamp(0.0, 1.0);

  return settings.velocityRestPressure +
      (settings.velocityMinPressure - settings.velocityRestPressure) *
          _studioBrushSmoothstep(t);
}

/// Cumulative arc length at each stroke point (first point is 0).
List<double> studioBrushArcLengths(List<Offset> points) {
  if (points.isEmpty) {
    return const [];
  }

  final lengths = <double>[0];
  for (var i = 1; i < points.length; i++) {
    lengths.add(
      lengths.last + (points[i] - points[i - 1]).distance,
    );
  }
  return lengths;
}

/// Whether stroke-length taper includes the trailing end fade.
enum StudioBrushStrokePhase {
  /// In-progress stroke on canvas: start taper + velocity only.
  live,

  /// Finished stroke in layer history: full start and end taper.
  committed,
}

/// Procreate-style size taper from stroke start and end (touch taper).
double studioBrushTaperSizeMultiplier({
  required double distanceFromStart,
  required double distanceFromEnd,
  required double brushSize,
  StudioBrushSettings settings = StudioBrushSettings.smoothMarker,
  StudioBrushStrokePhase phase = StudioBrushStrokePhase.committed,
}) {
  final tip = settings.taperTipSize.clamp(0.0, 1.0);
  if (tip >= 1) {
    return 1;
  }

  final startLen = brushSize * settings.startTaperLengthFactor;
  final endLen = brushSize * settings.endTaperLengthFactor;
  var multiplier = 1.0;

  if (startLen > 0) {
    final t = (distanceFromStart / startLen).clamp(0.0, 1.0);
    multiplier *= tip + (1 - tip) * _studioBrushSmoothstep(t);
  }

  if (endLen > 0 && phase == StudioBrushStrokePhase.committed) {
    final t = (distanceFromEnd / endLen).clamp(0.0, 1.0);
    multiplier *= tip + (1 - tip) * _studioBrushSmoothstep(t);
  }

  return multiplier.clamp(tip, 1.0);
}

/// Opacity taper at stroke tips (Procreate taper opacity).
double studioBrushTaperOpacityMultiplier({
  required double distanceFromStart,
  required double distanceFromEnd,
  required double brushSize,
  StudioBrushSettings settings = StudioBrushSettings.smoothMarker,
  StudioBrushStrokePhase phase = StudioBrushStrokePhase.committed,
}) {
  final tip = settings.taperTipOpacity.clamp(0.0, 1.0);
  if (tip >= 1) {
    return 1;
  }

  final startLen = brushSize * settings.startTaperLengthFactor;
  final endLen = brushSize * settings.endTaperLengthFactor;
  var multiplier = 1.0;

  if (startLen > 0) {
    final t = (distanceFromStart / startLen).clamp(0.0, 1.0);
    multiplier *= tip + (1 - tip) * _studioBrushSmoothstep(t);
  }

  if (endLen > 0 && phase == StudioBrushStrokePhase.committed) {
    final t = (distanceFromEnd / endLen).clamp(0.0, 1.0);
    multiplier *= tip + (1 - tip) * _studioBrushSmoothstep(t);
  }

  return multiplier.clamp(tip, 1.0);
}

bool pointerHasStylusPressure(PointerDeviceKind kind) {
  return kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus;
}

double normalizePointerPressure(double pressure) {
  if (pressure <= 0) {
    return 1;
  }
  return pressure.clamp(0.08, 1);
}

Offset stabilizeStudioPoint(Offset target, Offset anchor, double responsiveness) {
  return Offset.lerp(anchor, target, responsiveness)!;
}

double studioBrushRadius(
  double brushSize,
  double pressure, {
  StudioBrushSettings settings = StudioBrushSettings.smoothMarker,
}) {
  return brushSize *
      (settings.minRadiusFactor +
          (settings.maxRadiusFactor - settings.minRadiusFactor) * pressure) /
      2;
}

double studioBrushOpacity(
  double baseAlpha,
  double pressure, {
  StudioBrushSettings settings = StudioBrushSettings.smoothMarker,
}) {
  return (baseAlpha *
          (settings.minOpacityFactor +
              (settings.maxOpacityFactor - settings.minOpacityFactor) *
                  pressure))
      .clamp(0.05, 1);
}

/// Derive per-point pressure when a move adds multiple stamp points at once.
List<double> studioBrushPressuresForPoints({
  required Offset? previousPoint,
  required List<Offset> points,
  required double endPressure,
  required double brushSize,
  StudioBrushSettings settings = StudioBrushSettings.smoothMarker,
}) {
  if (points.isEmpty) {
    return const [];
  }

  final referenceStep = brushSize * settings.spacingFactor;
  return [
    for (var i = 0; i < points.length; i++)
      () {
        final from = i == 0 ? previousPoint : points[i - 1];
        if (from == null || referenceStep <= 0) {
          return endPressure;
        }

        final distance = (points[i] - from).distance;
        final local = studioBrushPressureFromVelocity(
          distance / referenceStep * 720,
          brushSize,
          settings: settings,
        );
        return (endPressure * 0.25 + local * 0.75).clamp(0.08, 1.0);
      }(),
  ];
}

/// Interpolate points along a segment for stamp placement.
List<Offset> studioBrushSegmentPoints({
  required Offset from,
  required Offset to,
  required double maxStep,
}) {
  if (maxStep <= 0) {
    return [to];
  }

  final delta = to - from;
  final distance = delta.distance;
  if (distance <= maxStep) {
    return distance == 0 ? const [] : [to];
  }

  final direction = delta / distance;
  final steps = (distance / maxStep).ceil();
  return [
    for (var i = 1; i <= steps; i++)
      from + direction * math.min(maxStep * i, distance),
  ];
}
