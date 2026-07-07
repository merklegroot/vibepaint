import 'package:flutter/material.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/painters/canvas_painter.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/canvas_geometry.dart';
import 'package:vibepaint/widgets/color_palette_panel.dart';

class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  static const canvasWidth = 1024.0;
  static const canvasHeight = 576.0;
  static const brushSize = 6.0;

  static final _canvasBounds = Rect.fromLTWH(0, 0, canvasWidth, canvasHeight);

  final _strokes = <Stroke>[];
  Stroke? _currentStroke;
  Offset? _lastPanPosition;
  int _selectedColorIndex = 0;

  Color get _primaryColor => AppColors.presetColors[_selectedColorIndex];

  String get _primaryHex {
    final value = _primaryColor.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  bool _isInsideCanvas(Offset position) {
    return isInsideCanvas(position, canvasWidth, canvasHeight);
  }

  void _beginPan(Offset position) {
    _lastPanPosition = position;
    _startStroke(position);
  }

  void _startStroke(Offset position) {
    if (!_isInsideCanvas(position)) {
      return;
    }

    setState(() {
      _currentStroke = Stroke(
        color: _primaryColor,
        brushSize: brushSize,
        points: [position],
      );
    });
  }

  void _commitCurrentStroke() {
    if (_currentStroke == null || _currentStroke!.isEmpty) {
      _currentStroke = null;
      return;
    }

    _strokes.add(_currentStroke!);
    _currentStroke = null;
  }

  void _extendStroke(Offset position) {
    final inside = _isInsideCanvas(position);

    if (!inside) {
      if (_currentStroke == null || _currentStroke!.points.isEmpty) {
        _lastPanPosition = position;
        return;
      }

      final last = _currentStroke!.points.last;
      if (!_isInsideCanvas(last)) {
        _lastPanPosition = position;
        return;
      }

      final exitPoints = strokeExtensionPoints(
        from: last,
        to: position,
        bounds: _canvasBounds,
        maxStep: brushSize / 2,
      );

      setState(() {
        if (exitPoints.isNotEmpty) {
          _currentStroke = _currentStroke!.copyWith(
            points: [..._currentStroke!.points, ...exitPoints],
          );
        }
        _commitCurrentStroke();
      });
      _lastPanPosition = position;
      return;
    }

    if (_currentStroke == null) {
      final from = _lastPanPosition;
      final points = from != null
          ? strokeReentryPoints(
              from: from,
              to: position,
              bounds: _canvasBounds,
              maxStep: brushSize / 2,
            )
          : [position];

      setState(() {
        _currentStroke = Stroke(
          color: _primaryColor,
          brushSize: brushSize,
          points: points,
        );
      });
      _lastPanPosition = position;
      return;
    }

    final last = _currentStroke!.points.last;
    final newPoints = strokeExtensionPoints(
      from: last,
      to: position,
      bounds: _canvasBounds,
      maxStep: brushSize / 2,
    );

    if (newPoints.isEmpty) {
      _lastPanPosition = position;
      return;
    }

    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, ...newPoints],
      );
    });
    _lastPanPosition = position;
  }

  void _endStroke() {
    _lastPanPosition = null;
    if (_currentStroke == null || _currentStroke!.isEmpty) {
      _currentStroke = null;
      return;
    }

    setState(_commitCurrentStroke);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.workspace,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorPalettePanel(
                      selectedIndex: _selectedColorIndex,
                      onSelected: (index) {
                        setState(() => _selectedColorIndex = index);
                      },
                    ),
                    const SizedBox(width: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.canvasBorder,
                          width: 2,
                        ),
                      ),
                      child: SizedBox(
                        width: canvasWidth,
                        height: canvasHeight,
                        child: ClipRect(
                          child: GestureDetector(
                            onPanStart: (details) =>
                                _beginPan(details.localPosition),
                            onPanUpdate: (details) =>
                                _extendStroke(details.localPosition),
                            onPanEnd: (_) => _endStroke(),
                            onPanCancel: () => _endStroke(),
                            child: CustomPaint(
                              painter: CanvasPainter(
                                strokes: _strokes,
                                currentStroke: _currentStroke,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.statusBar,
            child: Text(
              'Brush  |  $_primaryHex  |  Drag on the canvas to paint',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.statusText,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
