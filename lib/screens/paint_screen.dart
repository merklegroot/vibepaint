import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/painters/canvas_painter.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/canvas_geometry.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';
import 'package:vibepaint/widgets/color_palette_panel.dart';
import 'package:vibepaint/widgets/paint_toolbar.dart';
import 'package:vibepaint/widgets/tool_toolbar.dart';

class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  final _strokes = <Stroke>[];
  Stroke? _currentStroke;
  Offset? _lastPanPosition;
  int _selectedColorIndex = 0;
  double _brushSize = 6;
  PaintTool _activeTool = PaintTool.brush;

  Color get _primaryColor => AppColors.presetColors[_selectedColorIndex];

  Color get _strokeColor =>
      _activeTool == PaintTool.eraser ? Colors.white : _primaryColor;

  String get _primaryHex {
    final value = _primaryColor.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  bool _isInsideCanvas(Offset position, Rect bounds) {
    return isInsideCanvas(position, bounds.width, bounds.height);
  }

  void _changeBrushSize(double delta) {
    setState(() {
      _brushSize = (_brushSize + delta).clamp(
        BrushSizeControl.minSize,
        BrushSizeControl.maxSize,
      );
    });
  }

  void _beginPan(Offset position, Rect bounds) {
    _lastPanPosition = position;
    _startStroke(position, bounds);
  }

  void _startStroke(Offset position, Rect bounds) {
    if (!_isInsideCanvas(position, bounds)) {
      return;
    }

    setState(() {
      _currentStroke = Stroke(
        color: _strokeColor,
        brushSize: _brushSize,
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

  void _extendStroke(Offset position, Rect bounds) {
    final inside = _isInsideCanvas(position, bounds);

    if (!inside) {
      if (_currentStroke == null || _currentStroke!.points.isEmpty) {
        _lastPanPosition = position;
        return;
      }

      final last = _currentStroke!.points.last;
      if (!_isInsideCanvas(last, bounds)) {
        _lastPanPosition = position;
        return;
      }

      final exitPoints = strokeExtensionPoints(
        from: last,
        to: position,
        bounds: bounds,
        maxStep: _brushSize / 2,
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
              bounds: bounds,
              maxStep: _brushSize / 2,
            )
          : [position];

      setState(() {
        _currentStroke = Stroke(
          color: _strokeColor,
          brushSize: _brushSize,
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
      bounds: bounds,
      maxStep: _brushSize / 2,
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
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.bracketLeft): () =>
            _changeBrushSize(-2),
        const SingleActivator(LogicalKeyboardKey.bracketRight): () =>
            _changeBrushSize(2),
        const SingleActivator(LogicalKeyboardKey.keyB): () {
          setState(() => _activeTool = PaintTool.brush);
        },
        const SingleActivator(LogicalKeyboardKey.keyE): () {
          setState(() => _activeTool = PaintTool.eraser);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.workspace,
          body: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ToolToolbar(
                      selected: _activeTool,
                      onSelected: (tool) {
                        setState(() => _activeTool = tool);
                      },
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.canvasBorder,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PaintToolbar(
                              brushSize: _brushSize,
                              onBrushSizeChanged: (size) {
                                setState(() => _brushSize = size);
                              },
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final bounds = Offset.zero &
                                      Size(
                                        constraints.maxWidth,
                                        constraints.maxHeight,
                                      );

                                  return ClipRect(
                                    child: GestureDetector(
                                      onPanStart: (details) => _beginPan(
                                        details.localPosition,
                                        bounds,
                                      ),
                                      onPanUpdate: (details) =>
                                          _extendStroke(
                                        details.localPosition,
                                        bounds,
                                      ),
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
                                  );
                                },
                              ),
                            ),
                            Opacity(
                              opacity:
                                  _activeTool == PaintTool.brush ? 1 : 0.45,
                              child: IgnorePointer(
                                ignoring: _activeTool == PaintTool.eraser,
                                child: ColorPalettePanel(
                                  selectedIndex: _selectedColorIndex,
                                  onSelected: (index) {
                                    setState(
                                        () => _selectedColorIndex = index);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: AppColors.statusBar,
                child: Text(
                  '${_activeTool.label} ${_brushSize.round()}px  |  ${_activeTool == PaintTool.eraser ? 'White' : _primaryHex}  |  Drag on the canvas to paint',
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
        ),
      ),
    );
  }
}
