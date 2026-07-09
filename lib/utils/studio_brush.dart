import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';

/// Stabilization strength for the studio brush (0 = frozen, 1 = raw input).
const studioBrushResponsiveness = 0.42;

/// Minimum spacing between paint stamps as a fraction of brush size.
const studioBrushSpacingFactor = 0.14;

/// Light pressure for first contact before movement is sampled.
const studioBrushInitialTouchPressure = 0.26;

/// Distance (as a fraction of brush size) needed to ramp from initial touch
/// pressure to velocity-based pressure.
const studioBrushStartRampFactor = 0.16;

/// Maps pointer speed (document px / second) to synthetic brush pressure.
///
/// Pressure peaks at a slow drift and eases off at both extremes: a full stop
/// should not blob, and fast flicks should taper.
double studioBrushPressureFromVelocity(double velocityPxPerSec, double brushSize) {
  final reference = brushSize * 8;
  if (reference <= 0) {
    return 1;
  }

  const peakAt = 0.32;
  const restPressure = 0.48;
  const peakPressure = 0.8;
  const minPressure = 0.08;

  final normalized = (velocityPxPerSec / reference).clamp(0.0, 3.0);
  if (normalized <= peakAt) {
    return restPressure + (peakPressure - restPressure) * (normalized / peakAt);
  }

  final t = (normalized - peakAt) / (3.0 - peakAt);
  return peakPressure + (minPressure - peakPressure) * t;
}

/// Ease from a soft initial touch into velocity-based pressure once the
/// pointer has moved far enough from the stroke start.
double studioBrushPressureRamped({
  required double pressure,
  required double travelFromStart,
  required double brushSize,
}) {
  final rampDistance = brushSize * studioBrushStartRampFactor;
  if (rampDistance <= 0) {
    return pressure;
  }

  final moveT = (travelFromStart / rampDistance).clamp(0.0, 1.0);
  return studioBrushInitialTouchPressure +
      (pressure - studioBrushInitialTouchPressure) * moveT;
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

double studioBrushRadius(double brushSize, double pressure) {
  return brushSize * (0.22 + 0.78 * pressure) / 2;
}

double studioBrushOpacity(double baseAlpha, double pressure) {
  return (baseAlpha * (0.32 + 0.68 * pressure)).clamp(0.05, 1);
}

/// Derive per-point pressure when a move adds multiple stamp points at once.
List<double> studioBrushPressuresForPoints({
  required Offset? previousPoint,
  required List<Offset> points,
  required double endPressure,
  required double brushSize,
}) {
  if (points.isEmpty) {
    return const [];
  }

  final referenceStep = brushSize * studioBrushSpacingFactor;
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
