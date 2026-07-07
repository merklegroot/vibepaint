import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/stroke_history.dart';
import 'package:vibepaint/painters/canvas_painter.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/canvas_file_dialogs.dart';
import 'package:vibepaint/utils/canvas_geometry.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';
import 'package:vibepaint/widgets/color_palette_panel.dart';
import 'package:vibepaint/widgets/paint_toolbar.dart';
import 'package:vibepaint/widgets/tool_toolbar.dart';

class PaintScreen extends StatefulWidget {
  const PaintScreen({
    super.key,
    this.initialStrokes = const [],
    this.initialColorIndex = 0,
  });

  final List<Stroke> initialStrokes;
  final int initialColorIndex;

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  late final StrokeHistory _history;
  Stroke? _currentStroke;
  ui.Image? _backgroundImage;
  Offset? _lastPanPosition;
  late int _selectedColorIndex;
  double _brushSize = 6;
  PaintTool _activeTool = PaintTool.brush;
  ShapeStyle _shapeStyle = ShapeStyle.outline;
  Size _canvasSize = Size.zero;

  bool get _shiftPressed => HardwareKeyboard.instance.isShiftPressed;

  bool get _altPressed => HardwareKeyboard.instance.isAltPressed;

  @override
  void initState() {
    super.initState();
    _history = StrokeHistory(widget.initialStrokes);
    _selectedColorIndex = widget.initialColorIndex;
  }

  @override
  void dispose() {
    _backgroundImage?.dispose();
    super.dispose();
  }

  Color get _primaryColor => AppColors.presetColors[_selectedColorIndex];

  Color get _strokeColor =>
      _activeTool == PaintTool.eraser ? Colors.white : _primaryColor;

  String get _primaryHex {
    final value = _primaryColor.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String get _statusHint {
    if (!_activeTool.isDragShape) {
      return 'Drag on the canvas to paint';
    }

    final hints = <String>['Drag to draw'];
    if (_activeTool == PaintTool.line) {
      hints.add('Shift: 45°');
    } else {
      hints.add('Shift: square/circle');
      hints.add('Alt: from center');
    }
    return hints.join(' · ');
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
    switch (_activeTool) {
      case PaintTool.line:
        _startLine(position, bounds);
      case PaintTool.rectangle:
        _startBoundingShape(position, bounds, StrokeShape.rectangle);
      case PaintTool.ellipse:
        _startBoundingShape(position, bounds, StrokeShape.ellipse);
      default:
        _startStroke(position, bounds);
    }
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

    _history.add(_currentStroke!);
    _currentStroke = null;
  }

  void _undo() {
    if (!_history.canUndo) {
      return;
    }

    setState(_history.undo);
  }

  void _redo() {
    if (!_history.canRedo) {
      return;
    }

    setState(_history.redo);
  }

  Future<void> _clearCanvas() async {
    if (!_history.canUndo &&
        _currentStroke == null &&
        _backgroundImage == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.palettePanel,
        title: const Text(
          'Clear canvas?',
          style: TextStyle(color: AppColors.statusText),
        ),
        content: const Text(
          'This removes all strokes. This cannot be undone.',
          style: TextStyle(color: AppColors.paletteLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _history.clear();
      _currentStroke = null;
      _lastPanPosition = null;
      _backgroundImage?.dispose();
      _backgroundImage = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveCanvas() async {
    if (_currentStroke != null) {
      setState(_commitCurrentStroke);
    }

    if (_canvasSize == Size.zero) {
      return;
    }

    try {
      final bytes = await renderCanvasToPng(
        size: _canvasSize,
        strokes: _history.strokes,
        backgroundImage: _backgroundImage,
      );
      final path = await savePngFile(bytes);
      if (!mounted) {
        return;
      }
      if (path != null) {
        _showMessage('Saved $path');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Save failed: $error');
      }
    }
  }

  Future<void> _openCanvas() async {
    try {
      final image = await pickPngImage();
      if (!mounted || image == null) {
        return;
      }

      setState(() {
        _history.clear();
        _currentStroke = null;
        _lastPanPosition = null;
        _backgroundImage?.dispose();
        _backgroundImage = image;
      });
      _showMessage('Opened PNG');
    } catch (error) {
      if (mounted) {
        _showMessage('Open failed: $error');
      }
    }
  }

  void _startLine(Offset position, Rect bounds) {
    if (!_isInsideCanvas(position, bounds)) {
      return;
    }

    setState(() {
      _currentStroke = Stroke(
        color: _strokeColor,
        brushSize: _brushSize,
        points: [position, position],
        shape: StrokeShape.line,
      );
    });
  }

  void _startBoundingShape(
    Offset position,
    Rect bounds,
    StrokeShape shape,
  ) {
    if (!_isInsideCanvas(position, bounds)) {
      return;
    }

    setState(() {
      _currentStroke = Stroke(
        color: _strokeColor,
        brushSize: _brushSize,
        points: [position, position],
        shape: shape,
        style: _shapeStyle,
      );
    });
  }

  void _extendBoundingShape(Offset position, Rect bounds) {
    if (_currentStroke == null || _currentStroke!.points.isEmpty) {
      return;
    }

    final start = _currentStroke!.points.first;
    final corners = clippedShapeBounds(
      start: start,
      end: position,
      bounds: bounds,
      constrainSquare: _shiftPressed,
      fromCenter: _altPressed,
    );
    if (corners == null) {
      return;
    }

    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [corners.topLeft, corners.bottomRight],
      );
    });
  }

  void _endBoundingShape() {
    _lastPanPosition = null;
    if (_currentStroke == null || _currentStroke!.points.length < 2) {
      _currentStroke = null;
      return;
    }

    final rect = Rect.fromPoints(
      _currentStroke!.points.first,
      _currentStroke!.points.last,
    );
    if (rect.width <= 0 || rect.height <= 0) {
      _currentStroke = null;
      return;
    }

    setState(_commitCurrentStroke);
  }

  void _extendLine(Offset position, Rect bounds) {
    if (_currentStroke == null || _currentStroke!.points.isEmpty) {
      return;
    }

    final start = _currentStroke!.points.first;
    final end = clippedLineEnd(
      start: start,
      end: position,
      bounds: bounds,
      constrainAngle: _shiftPressed,
    );
    if (end == null) {
      return;
    }

    setState(() {
      _currentStroke = _currentStroke!.copyWith(points: [start, end]);
    });
  }

  void _endLine() {
    _lastPanPosition = null;
    if (_currentStroke == null || _currentStroke!.points.length < 2) {
      _currentStroke = null;
      return;
    }

    final start = _currentStroke!.points.first;
    final end = _currentStroke!.points.last;
    if (start == end) {
      _currentStroke = null;
      return;
    }

    setState(_commitCurrentStroke);
  }

  void _extendStroke(Offset position, Rect bounds) {
    switch (_activeTool) {
      case PaintTool.line:
        _extendLine(position, bounds);
        return;
      case PaintTool.rectangle:
      case PaintTool.ellipse:
        _extendBoundingShape(position, bounds);
        return;
      default:
        break;
    }

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
    switch (_activeTool) {
      case PaintTool.line:
        _endLine();
        return;
      case PaintTool.rectangle:
      case PaintTool.ellipse:
        _endBoundingShape();
        return;
      default:
        break;
    }

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
        const SingleActivator(LogicalKeyboardKey.keyL): () {
          setState(() => _activeTool = PaintTool.line);
        },
        const SingleActivator(LogicalKeyboardKey.keyR): () {
          setState(() => _activeTool = PaintTool.rectangle);
        },
        const SingleActivator(LogicalKeyboardKey.keyC): () {
          setState(() => _activeTool = PaintTool.ellipse);
        },
        const SingleActivator(LogicalKeyboardKey.keyE): () {
          setState(() => _activeTool = PaintTool.eraser);
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): _redo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): _redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
            _saveCanvas(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            _saveCanvas(),
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () =>
            _openCanvas(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
            _openCanvas(),
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          meta: true,
          shift: true,
        ): () => _clearCanvas(),
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
          shift: true,
        ): () => _clearCanvas(),
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
                              shapeStyle: _activeTool.supportsFillStyle
                                  ? _shapeStyle
                                  : null,
                              onShapeStyleChanged:
                                  _activeTool.supportsFillStyle
                                      ? (style) {
                                          setState(() => _shapeStyle = style);
                                        }
                                      : null,
                              canUndo: _history.canUndo,
                              canRedo: _history.canRedo,
                              canSave: _canvasSize != Size.zero,
                              canClear: _history.canUndo ||
                                  _currentStroke != null ||
                                  _backgroundImage != null,
                              onUndo: _undo,
                              onRedo: _redo,
                              onOpen: () => _openCanvas(),
                              onSave: () => _saveCanvas(),
                              onClear: () => _clearCanvas(),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final bounds = Offset.zero &
                                      Size(
                                        constraints.maxWidth,
                                        constraints.maxHeight,
                                      );
                                  _canvasSize = bounds.size;

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
                                          strokes: _history.strokes,
                                          currentStroke: _currentStroke,
                                          backgroundImage: _backgroundImage,
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
                                  _activeTool == PaintTool.eraser ? 0.45 : 1,
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
                  '${_activeTool.label} ${_brushSize.round()}px  |  ${_activeTool == PaintTool.eraser ? 'White' : _primaryHex}  |  $_statusHint',
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
