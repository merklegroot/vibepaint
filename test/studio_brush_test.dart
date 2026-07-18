import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/models/studio_brush_preset.dart';
import 'package:vibepaint/utils/studio_brush.dart';

void main() {
  test('normalizePointerPressure defaults mouse input to full pressure', () {
    expect(normalizePointerPressure(0), 1);
    expect(normalizePointerPressure(1), 1);
  });

  test('stabilizeStudioPoint eases toward the target', () {
    const anchor = Offset(0, 0);
    const target = Offset(100, 0);

    final eased = stabilizeStudioPoint(
      target,
      anchor,
      studioBrushResponsiveness,
    );

    expect(eased.dx, greaterThan(0));
    expect(eased.dx, lessThan(100));
  });

  test('studioBrushFilterSpeed smooths raw speed changes', () {
    const filtered = 100.0;
    final next = studioBrushFilterSpeed(
      rawSpeedPxPerSec: 0,
      filteredSpeedPxPerSec: filtered,
      dtSeconds: 0.016,
      slowness: 0.05,
    );

    expect(next, lessThan(filtered));
    expect(next, greaterThan(0));
  });

  test('studioBrushPressureFromVelocity tapers fast strokes', () {
    final slow = studioBrushPressureFromVelocity(40, 12);
    final fast = studioBrushPressureFromVelocity(800, 12);

    expect(slow, greaterThan(fast));
    expect(fast, lessThan(0.75));
  });

  test('studioBrushPressureFromVelocity is thicker at rest than at speed', () {
    final stopped = studioBrushPressureFromVelocity(0, 12);
    final moving = studioBrushPressureFromVelocity(300, 12);

    expect(stopped, greaterThan(moving));
  });

  test('log speed mapping compresses near-zero speeds', () {
    const settings = StudioBrushSettings.smoothMarker;
    final stopped = studioBrushPressureFromVelocity(0, 12, settings: settings);
    final crawl = studioBrushPressureFromVelocity(8, 12, settings: settings);

    expect(stopped, settings.velocityRestPressure);
    expect(crawl - stopped, lessThanOrEqualTo(0.08));
  });

  test('studioBrushPressureFromVelocity tapers down gradually when fast', () {
    const settings = StudioBrushSettings.smoothMarker;
    const brushSize = 12.0;
    final reference = brushSize * 8;
    final slow = studioBrushPressureFromVelocity(
      reference * 0.2,
      brushSize,
      settings: settings,
    );
    final medium = studioBrushPressureFromVelocity(
      reference * 1.0,
      brushSize,
      settings: settings,
    );
    final veryFast = studioBrushPressureFromVelocity(
      reference * 3,
      brushSize,
      settings: settings,
    );

    expect(medium, lessThan(slow));
    expect(veryFast, lessThan(medium));
    expect(veryFast, closeTo(settings.velocityMinPressure, 0.001));
  });

  test('studioBrushTaperSizeMultiplier fades stroke tips', () {
    const settings = StudioBrushSettings.smoothMarker;
    const brushSize = 12.0;

    expect(
      studioBrushTaperSizeMultiplier(
        distanceFromStart: 0,
        distanceFromEnd: 40,
        brushSize: brushSize,
        settings: settings,
      ),
      lessThan(0.5),
    );
    expect(
      studioBrushTaperSizeMultiplier(
        distanceFromStart: brushSize * settings.startTaperLengthFactor,
        distanceFromEnd: brushSize * settings.endTaperLengthFactor,
        brushSize: brushSize,
        settings: settings,
      ),
      1,
    );
  });

  test('live stroke phase skips end taper', () {
    const settings = StudioBrushSettings.smoothMarker;
    const brushSize = 12.0;

    final committed = studioBrushTaperSizeMultiplier(
      distanceFromStart: 40,
      distanceFromEnd: 0,
      brushSize: brushSize,
      settings: settings,
      phase: StudioBrushStrokePhase.committed,
    );
    final live = studioBrushTaperSizeMultiplier(
      distanceFromStart: 40,
      distanceFromEnd: 0,
      brushSize: brushSize,
      settings: settings,
      phase: StudioBrushStrokePhase.live,
    );

    expect(committed, lessThan(0.5));
    expect(live, 1);
  });

  test('live stroke phase still applies start taper', () {
    const settings = StudioBrushSettings.smoothMarker;
    const brushSize = 12.0;

    final live = studioBrushTaperSizeMultiplier(
      distanceFromStart: 0,
      distanceFromEnd: 40,
      brushSize: brushSize,
      settings: settings,
      phase: StudioBrushStrokePhase.live,
    );

    expect(live, lessThan(0.5));
  });

  test('studioBrushPressuresForPoints tapers long interpolated steps', () {
    final pressures = studioBrushPressuresForPoints(
      previousPoint: Offset.zero,
      points: const [Offset(20, 0), Offset(40, 0)],
      endPressure: 0.9,
      brushSize: 12,
    );

    expect(pressures.length, 2);
    expect(pressures.first, lessThan(0.9));
    expect(pressures.last, lessThanOrEqualTo(pressures.first));
  });
}
