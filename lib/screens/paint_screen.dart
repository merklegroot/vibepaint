import 'package:flutter/material.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/painters/canvas_painter.dart';
import 'package:vibepaint/theme/app_colors.dart';
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

  final _strokes = <Stroke>[];
  Stroke? _currentStroke;
  int _selectedColorIndex = 0;

  Color get _primaryColor => AppColors.presetColors[_selectedColorIndex];

  String get _primaryHex {
    final value = _primaryColor.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  bool _isInsideCanvas(Offset position) {
    return position.dx >= 0 &&
        position.dy >= 0 &&
        position.dx <= canvasWidth &&
        position.dy <= canvasHeight;
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

  void _extendStroke(Offset position) {
    if (_currentStroke == null || !_isInsideCanvas(position)) {
      return;
    }

    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, position],
      );
    });
  }

  void _endStroke() {
    if (_currentStroke == null || _currentStroke!.isEmpty) {
      _currentStroke = null;
      return;
    }

    setState(() {
      _strokes.add(_currentStroke!);
      _currentStroke = null;
    });
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
                                _startStroke(details.localPosition),
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
