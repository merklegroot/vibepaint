import 'dart:math';
import 'dart:ui';

class CanvasViewport {
  const CanvasViewport({
    this.scale = 1.0,
    this.pan = Offset.zero,
  });

  static const double minScale = 0.1;
  static const double maxScale = 8.0;
  static const double scrollZoomFactor = 1.1;

  final double scale;
  final Offset pan;

  int get zoomPercent => (scale * 100).round();

  String get zoomPercentLabel {
    final percent = scale * 100;
    if (percent >= 100) {
      return '${percent.round()}';
    }
    if (percent >= 10) {
      return '${percent.round()}';
    }
    return percent.toStringAsFixed(1);
  }

  Offset viewportToDocument(Offset viewportPoint) {
    return (viewportPoint - pan) / scale;
  }

  Offset documentToViewport(Offset documentPoint) {
    return documentPoint * scale + pan;
  }

  CanvasViewport zoomAt(Offset viewportFocal, double newScale) {
    final clampedScale = newScale.clamp(minScale, maxScale);
    final documentFocal = viewportToDocument(viewportFocal);
    return CanvasViewport(
      scale: clampedScale,
      pan: viewportFocal - documentFocal * clampedScale,
    );
  }

  CanvasViewport zoomByAt(Offset viewportFocal, double factor) {
    return zoomAt(viewportFocal, scale * factor);
  }

  CanvasViewport panBy(Offset delta) {
    return CanvasViewport(scale: scale, pan: pan + delta);
  }

  CanvasViewport resetZoom() {
    return const CanvasViewport();
  }

  CanvasViewport fitToWindow(Size viewportSize, Size documentSize) {
    if (viewportSize == Size.zero || documentSize == Size.zero) {
      return this;
    }

    final scaleX = viewportSize.width / documentSize.width;
    final scaleY = viewportSize.height / documentSize.height;
    final fitScale = min(scaleX, scaleY).clamp(minScale, maxScale);
    final scaledWidth = documentSize.width * fitScale;
    final scaledHeight = documentSize.height * fitScale;

    return CanvasViewport(
      scale: fitScale,
      pan: Offset(
        (viewportSize.width - scaledWidth) / 2,
        (viewportSize.height - scaledHeight) / 2,
      ),
    );
  }
}
