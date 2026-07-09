import 'dart:math' as math;
import 'dart:ui';

/// Stabilization strength for the studio brush (0 = frozen, 1 = raw input).
const studioBrushResponsiveness = 0.42;

/// Minimum spacing between paint stamps as a fraction of brush size.
const studioBrushSpacingFactor = 0.14;

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
  return brushSize * (0.35 + 0.65 * pressure) / 2;
}

double studioBrushOpacity(double baseAlpha, double pressure) {
  return (baseAlpha * (0.45 + 0.55 * pressure)).clamp(0.05, 1);
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
