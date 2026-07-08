import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/menus/platform_file_menus.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/layer_stack.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/painters/canvas_painter.dart';
import 'package:vibepaint/painters/selection_overlay_painter.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/theme/color_wells.dart';
import 'package:vibepaint/utils/canvas_file_dialogs.dart';
import 'package:vibepaint/utils/canvas_geometry.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';
import 'package:vibepaint/utils/document_title.dart';
import 'package:vibepaint/utils/native_window_title.dart';
import 'package:vibepaint/utils/selection_geometry.dart';
import 'package:vibepaint/widgets/app_menu_bar.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';
import 'package:vibepaint/widgets/color_palette_panel.dart';
import 'package:vibepaint/widgets/layers_panel.dart';
import 'package:vibepaint/widgets/new_image_dialog.dart';
import 'package:vibepaint/widgets/paint_toolbar.dart';
import 'package:vibepaint/widgets/save_image_dialog.dart';
import 'package:vibepaint/widgets/tool_toolbar.dart';

class PaintScreen extends StatefulWidget {
  const PaintScreen({
    super.key,
    this.initialStrokes = const [],
    this.initialColorIndex = 0,
    this.initialTool = PaintTool.brush,
    this.initialShapeStyle = ShapeStyle.outline,
  });

  final List<Stroke> initialStrokes;
  final int initialColorIndex;
  final PaintTool initialTool;
  final ShapeStyle initialShapeStyle;

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen>
    with SingleTickerProviderStateMixin {
  late final LayerStack _layerStack;
  Stroke? _currentStroke;
  Offset? _lastPanPosition;
  late int _selectedColorIndex;
  double _brushSize = 6;
  PaintTool _activeTool = PaintTool.brush;
  ShapeStyle _shapeStyle = ShapeStyle.outline;
  Size _canvasSize = Size.zero;
  String? _documentPath;
  int _editGeneration = 0;
  int _savedGeneration = 0;
  ColorWellTarget _colorTarget = ColorWellTarget.primary;
  CanvasSelection? _selection;
  CanvasSelection? _selectionDraft;
  Offset? _selectionDragStart;
  bool _movingSelection = false;
  Offset? _moveStart;
  List<Stroke>? _strokesBeforeMove;
  late final AnimationController _marchingAntsController;

  bool get _isDirty => _editGeneration != _savedGeneration;

  bool get _shiftPressed => HardwareKeyboard.instance.isShiftPressed;

  bool get _altPressed => HardwareKeyboard.instance.isAltPressed;

  bool get _subtractSelectionModifier =>
      HardwareKeyboard.instance.isControlPressed;

  @override
  void initState() {
    super.initState();
    _layerStack = LayerStack(initialStrokes: widget.initialStrokes);
    _selectedColorIndex = widget.initialColorIndex;
    _activeTool = widget.initialTool;
    _shapeStyle = widget.initialShapeStyle;
    if (widget.initialStrokes.isNotEmpty) {
      _editGeneration = 1;
    }
    _marchingAntsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWindowTitle());
  }

  void _syncWindowTitle() {
    syncNativeWindowTitle(
      formatDocumentTitle(
        documentPath: _documentPath,
        isDirty: _isDirty,
      ),
    );
  }

  void _noteDocumentEdited() {
    _editGeneration++;
    _syncWindowTitle();
  }

  void _noteDocumentSaved() {
    _savedGeneration = _editGeneration;
    _syncWindowTitle();
  }

  void _resetDocumentTracking({String? path, bool edited = false}) {
    _documentPath = path;
    _editGeneration = edited ? 1 : 0;
    _savedGeneration = 0;
    _syncWindowTitle();
  }

  Future<void> _deleteLayer(int index) async {
    final layer = _layerStack.layers[index];
    if (layer.history.canUndo) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.palettePanel,
          title: const Text(
            'Delete layer?',
            style: TextStyle(color: AppColors.statusText),
          ),
          content: Text(
            'Delete "${layer.name}"? This cannot be undone.',
            style: const TextStyle(color: AppColors.paletteLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _layerStack.deleteLayer(index));
    _noteDocumentEdited();
  }

  Future<void> _mergeDownLayer(int index) async {
    setState(() => _layerStack.mergeDown(index));
    _noteDocumentEdited();
  }

  @override
  void dispose() {
    _marchingAntsController.dispose();
    _layerStack.dispose();
    super.dispose();
  }

  Color get _primaryColor => AppColors.presetColors[_selectedColorIndex];

  bool get _isErasing => _activeTool == PaintTool.eraser;

  String get _colorStatusLabel {
    if (_isErasing) {
      return 'Eraser';
    }
    if (_colorTarget == ColorWellTarget.canvasBackground) {
      return 'Background ${colorWellHex(_layerStack.backgroundColor)}';
    }
    return colorWellHex(_primaryColor);
  }

  void _swapColors() {
    setState(() {
      final primary = _primaryColor;
      final canvas = _layerStack.backgroundColor;
      _layerStack.setBackgroundColor(primary);
      if (isTransparentCanvasBackground(canvas)) {
        _selectedColorIndex = defaultPrimaryColorIndex;
      } else {
        _selectedColorIndex =
            presetColorIndex(canvas) ?? defaultPrimaryColorIndex;
      }
    });
    _noteDocumentEdited();
  }

  void _resetColors() {
    setState(() {
      _selectedColorIndex = defaultPrimaryColorIndex;
      _layerStack.setBackgroundColor(defaultCanvasBackground);
    });
    _noteDocumentEdited();
  }

  String get _statusHint {
    if (_activeTool.isSelectionTool) {
      final hints = <String>['Drag to select'];
      if (_selection != null) {
        hints.add('Drag inside to move');
      }
      hints.add('Shift: add');
      hints.add('Ctrl: subtract');
      return hints.join(' · ');
    }

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

  SelectionShape get _activeSelectionShape =>
      _activeTool == PaintTool.ellipseSelect
          ? SelectionShape.ellipse
          : SelectionShape.rectangle;

  CanvasSelection? get _activeSelectionOverlay =>
      _selectionDraft ?? _selection;

  void _selectAll() {
    if (_canvasSize == Size.zero) {
      return;
    }
    setState(() {
      _selection = CanvasSelection.all(_canvasSize);
      _selectionDraft = null;
    });
  }

  void _deselect() {
    if (_selection == null && _selectionDraft == null) {
      return;
    }
    setState(() {
      _selection = null;
      _selectionDraft = null;
      _movingSelection = false;
      _moveStart = null;
      _strokesBeforeMove = null;
    });
  }

  void _invertSelection() {
    if (_selection == null || _canvasSize == Size.zero) {
      return;
    }
    setState(() {
      _selection = _selection!.inverted(_canvasSize);
    });
    _noteDocumentEdited();
  }

  void _deleteSelection() {
    if (_selection == null) {
      return;
    }
    setState(() {
      _layerStack.activeHistory.removeWhere(
        (stroke) => strokeIntersectsSelection(_selection!, stroke),
      );
    });
    _noteDocumentEdited();
  }

  void _beginSelectionDrag(Offset position, Rect bounds) {
    if (!_isInsideCanvas(position, bounds)) {
      return;
    }

    setState(() {
      _selectionDragStart = position;
      _selectionDraft = CanvasSelection.fromRect(
        _activeSelectionShape,
        Rect.fromPoints(position, position),
      );
    });
  }

  void _extendSelectionDrag(Offset position, Rect bounds) {
    if (_selectionDragStart == null) {
      return;
    }

    final corners = clippedShapeBounds(
      start: _selectionDragStart!,
      end: position,
      bounds: bounds,
      constrainSquare: _shiftPressed && !_subtractSelectionModifier,
      fromCenter: false,
    );
    if (corners == null) {
      return;
    }

    setState(() {
      _selectionDraft = CanvasSelection.fromRect(
        _activeSelectionShape,
        Rect.fromPoints(corners.topLeft, corners.bottomRight),
      );
    });
  }

  void _endSelectionDrag() {
    _selectionDragStart = null;
    final draft = _selectionDraft;
    _selectionDraft = null;
    if (draft == null || draft.isEmpty) {
      return;
    }

    setState(() {
      if (_selection == null ||
          (!_shiftPressed && !_subtractSelectionModifier)) {
        _selection = draft;
        return;
      }

      if (_shiftPressed && !_subtractSelectionModifier) {
        _selection = _selection!.combined(draft, PathOperation.union);
      } else if (_subtractSelectionModifier && !_shiftPressed) {
        _selection = _selection!.combined(draft, PathOperation.difference);
      } else {
        _selection = _selection!.combined(draft, PathOperation.intersect);
      }
    });
  }

  void _beginMoveSelection(Offset position) {
    _movingSelection = true;
    _moveStart = position;
    _strokesBeforeMove = List<Stroke>.from(_layerStack.activeHistory.strokes);
  }

  void _extendMoveSelection(Offset position) {
    if (!_movingSelection ||
        _moveStart == null ||
        _selection == null ||
        _strokesBeforeMove == null) {
      return;
    }

    final delta = position - _moveStart!;
    setState(() {
      _layerStack.activeHistory.replaceStrokes(
        translateSelectedStrokes(
          _strokesBeforeMove!,
          _selection!,
          delta,
        ),
      );
    });
  }

  void _endMoveSelection() {
    if (!_movingSelection) {
      return;
    }

    _movingSelection = false;
    _moveStart = null;
    _strokesBeforeMove = null;
    _noteDocumentEdited();
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
    if (_activeTool.isSelectionTool) {
      if (_selection != null && _selection!.contains(position)) {
        _beginMoveSelection(position);
      } else {
        _beginSelectionDrag(position, bounds);
      }
      return;
    }

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
        color: _primaryColor,
        brushSize: _brushSize,
        points: [position],
        isEraser: _isErasing,
      );
    });
  }

  void _commitCurrentStroke() {
    if (_currentStroke == null || _currentStroke!.isEmpty) {
      _currentStroke = null;
      return;
    }

    _layerStack.activeHistory.add(_currentStroke!);
    _currentStroke = null;
    _noteDocumentEdited();
  }

  void _undo() {
    if (!_layerStack.canUndo) {
      return;
    }

    setState(_layerStack.activeHistory.undo);
    _noteDocumentEdited();
  }

  void _redo() {
    if (!_layerStack.canRedo) {
      return;
    }

    setState(_layerStack.activeHistory.redo);
    _noteDocumentEdited();
  }

  Future<void> _clearCanvas() async {
    if (!_layerStack.hasContent && _currentStroke == null) {
      return;
    }

    final backgroundColor = await showDialog<Color>(
      context: context,
      builder: (context) => const NewImageDialog(),
    );

    if (backgroundColor == null || !mounted) {
      return;
    }

    setState(() {
      _layerStack.clear();
      _layerStack.setBackgroundColor(backgroundColor);
      _currentStroke = null;
      _lastPanPosition = null;
      _selection = null;
      _selectionDraft = null;
    });
    _resetDocumentTracking();
  }

  Future<Uint8List?> _renderCanvasBytes(ImageFileFormat format) async {
    if (_currentStroke != null) {
      setState(_commitCurrentStroke);
    }

    if (_canvasSize == Size.zero) {
      return null;
    }

    return renderCanvasToBytes(
      size: _canvasSize,
      layers: _layerStack.layers,
      backgroundImage: _layerStack.backgroundImage,
      backgroundColor: _layerStack.backgroundColor,
      format: format,
    );
  }

  Future<void> _saveCanvas() async {
    if (_documentPath != null) {
      await _saveToPath(_documentPath!);
      return;
    }

    await _saveCanvasAs();
  }

  Future<void> _saveCanvasAs() async {
    try {
      final initialFormat =
          imageFormatFromPath(_documentPath ?? '') ?? ImageFileFormat.png;
      final defaultName = defaultSaveFileName(
        documentPath: _documentPath,
        format: initialFormat,
      );

      String? path;
      if (useNativeSaveFormatPicker) {
        path = await saveImageViaNativeDialog(
          fileName: defaultName,
          initialDirectory: parentDirectoryPath(_documentPath),
          encode: _renderCanvasBytes,
        );
      } else {
        if (!mounted) {
          return;
        }
        final request = await showSaveImageDialog(
          context,
          documentPath: _documentPath,
          initialFormat: initialFormat,
        );
        if (request == null || !mounted) {
          return;
        }

        final bytes = await _renderCanvasBytes(request.format);
        if (bytes == null || !mounted) {
          return;
        }

        await writeImageFile(request.path, bytes);
        path = request.path;
      }

      if (!mounted || path == null) {
        return;
      }

      setState(() => _documentPath = path);
      _noteDocumentSaved();
      _showMessage('Saved $path');
    } catch (error) {
      if (mounted) {
        _showMessage('Save failed: $error');
      }
    }
  }

  Future<void> _saveToPath(String path) async {
    try {
      final format = imageFormatFromPath(path) ?? ImageFileFormat.png;
      final bytes = await _renderCanvasBytes(format);
      if (bytes == null || !mounted) {
        return;
      }

      await writeImageFile(path, bytes);
      if (mounted) {
        _noteDocumentSaved();
        _showMessage('Saved $path');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Save failed: $error');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openCanvas() async {
    try {
      final picked = await pickImageFile();
      if (!mounted || picked == null) {
        return;
      }

      setState(() {
        _layerStack.clear();
        _layerStack.setBackgroundImage(picked.image);
        _currentStroke = null;
        _lastPanPosition = null;
      });
      _resetDocumentTracking(path: picked.path);
      _showMessage('Opened ${picked.path}');
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
        color: _primaryColor,
        brushSize: _brushSize,
        points: [position, position],
        shape: StrokeShape.line,
        isEraser: _isErasing,
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
        color: _primaryColor,
        brushSize: _brushSize,
        points: [position, position],
        shape: shape,
        style: _shapeStyle,
        isEraser: _isErasing,
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
    if (_activeTool.isSelectionTool) {
      if (_movingSelection) {
        _extendMoveSelection(position);
      } else {
        _extendSelectionDrag(position, bounds);
      }
      return;
    }

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
          color: _primaryColor,
          brushSize: _brushSize,
          points: points,
          isEraser: _isErasing,
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
    if (_activeTool.isSelectionTool) {
      if (_movingSelection) {
        _endMoveSelection();
      } else {
        _endSelectionDrag();
      }
      _lastPanPosition = null;
      return;
    }

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
    final canNew = true;

    final body = CallbackShortcuts(
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
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          meta: true,
          shift: true,
        ): () => _saveCanvasAs(),
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          control: true,
          shift: true,
        ): () => _saveCanvasAs(),
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () =>
            _openCanvas(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
            _openCanvas(),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
            _clearCanvas(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            _clearCanvas(),
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true): _selectAll,
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            _selectAll,
        const SingleActivator(LogicalKeyboardKey.keyD, meta: true): _deselect,
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            _deselect,
        const SingleActivator(
          LogicalKeyboardKey.keyI,
          control: true,
          shift: true,
        ): _invertSelection,
        const SingleActivator(
          LogicalKeyboardKey.keyI,
          meta: true,
          shift: true,
        ): _invertSelection,
        const SingleActivator(LogicalKeyboardKey.delete): _deleteSelection,
        const SingleActivator(LogicalKeyboardKey.backspace): _deleteSelection,
        const SingleActivator(LogicalKeyboardKey.escape): _deselect,
        const SingleActivator(LogicalKeyboardKey.keyS): () {
          setState(() => _activeTool = PaintTool.rectSelect);
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
                            AppMenuBar(
                              canNew: canNew,
                              onNew: () => _clearCanvas(),
                              onOpen: _openCanvas,
                              onSave: () => _saveCanvas(),
                              onSaveAs: () => _saveCanvasAs(),
                              onSelectAll: _selectAll,
                              onDeselect: _deselect,
                              onInvertSelection: _invertSelection,
                              onDeleteSelection: _deleteSelection,
                              hasSelection: _selection != null,
                            ),
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
                              canUndo: _layerStack.canUndo,
                              canRedo: _layerStack.canRedo,
                              onUndo: _undo,
                              onRedo: _redo,
                              hasSelection: _selection != null,
                              onSelectAll: _selectAll,
                              onDeselect: _deselect,
                              onInvertSelection: _invertSelection,
                              onDeleteSelection: _deleteSelection,
                            ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final size = Size(
                                          constraints.maxWidth,
                                          constraints.maxHeight,
                                        );
                                        _canvasSize = size;
                                        final bounds = Offset.zero & size;

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
                                            child: AnimatedBuilder(
                                              animation: _marchingAntsController,
                                              builder: (context, child) {
                                                return Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    child!,
                                                    CustomPaint(
                                                      painter:
                                                          SelectionOverlayPainter(
                                                        selection:
                                                            _activeSelectionOverlay,
                                                        dashPhase:
                                                            _marchingAntsController
                                                                    .value *
                                                                16,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                              child: CustomPaint(
                                                painter: CanvasPainter(
                                                  layers: _layerStack.layers,
                                                  activeLayerIndex:
                                                      _layerStack.activeIndex,
                                                  currentStroke: _currentStroke,
                                                  backgroundImage:
                                                      _layerStack.backgroundImage,
                                                  backgroundColor:
                                                      _layerStack.backgroundColor,
                                                ),
                                                child: const SizedBox.expand(),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  LayersPanel(
                                    layers: _layerStack.layers,
                                    activeIndex: _layerStack.activeIndex,
                                    canDeleteLayer: _layerStack.canDeleteLayer,
                                    canMoveLayerUp: _layerStack.canMoveLayerUp,
                                    canMoveLayerDown:
                                        _layerStack.canMoveLayerDown,
                                    canMergeDown: _layerStack.canMergeDown,
                                    onLayerSelected: (index) {
                                      setState(
                                        () => _layerStack.setActiveLayer(index),
                                      );
                                    },
                                    onToggleVisibility: (index) {
                                      setState(
                                        () => _layerStack.toggleVisibility(index),
                                      );
                                      _noteDocumentEdited();
                                    },
                                    onAddLayer: () {
                                      setState(_layerStack.addLayer);
                                      _noteDocumentEdited();
                                    },
                                    onDuplicateLayer: (index) {
                                      setState(
                                        () => _layerStack.duplicateLayer(index),
                                      );
                                      _noteDocumentEdited();
                                    },
                                    onDeleteLayer: _deleteLayer,
                                    onMoveLayerUp: (index) {
                                      setState(
                                        () => _layerStack.moveLayerUp(index),
                                      );
                                      _noteDocumentEdited();
                                    },
                                    onMoveLayerDown: (index) {
                                      setState(
                                        () => _layerStack.moveLayerDown(index),
                                      );
                                      _noteDocumentEdited();
                                    },
                                    onMergeDown: _mergeDownLayer,
                                    onRenameLayer: (index, name) {
                                      setState(
                                        () => _layerStack.renameLayer(index, name),
                                      );
                                      _noteDocumentEdited();
                                    },
                                    onOpacityChanged: (opacity) {
                                      setState(
                                        () => _layerStack.setLayerOpacity(
                                          _layerStack.activeIndex,
                                          opacity,
                                        ),
                                      );
                                      _noteDocumentEdited();
                                    },
                                    onBlendModeChanged: (mode) {
                                      setState(
                                        () => _layerStack.setLayerBlendMode(
                                          _layerStack.activeIndex,
                                          mode,
                                        ),
                                      );
                                      _noteDocumentEdited();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Opacity(
                              opacity:
                                  _activeTool == PaintTool.eraser ? 0.45 : 1,
                              child: IgnorePointer(
                                ignoring: _activeTool == PaintTool.eraser,
                                child: ColorPalettePanel(
                                  selectedIndex: _selectedColorIndex,
                                  canvasBackgroundColor:
                                      _layerStack.backgroundColor,
                                  colorTarget: _colorTarget,
                                  onColorTargetChanged: (target) {
                                    setState(() => _colorTarget = target);
                                  },
                                  onPrimarySelected: (index) {
                                    setState(() => _selectedColorIndex = index);
                                  },
                                  onCanvasBackgroundChanged: (color) {
                                    setState(
                                      () => _layerStack.setBackgroundColor(color),
                                    );
                                    _noteDocumentEdited();
                                  },
                                  onSwapColors: _swapColors,
                                  onResetColors: _resetColors,
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
                  '${_activeTool.label} ${_brushSize.round()}px  |  $_colorStatusLabel  |  ${_layerStack.activeLayer.name}  |  $_statusHint',
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

    if (usePlatformFileMenu) {
      return PlatformMenuBar(
        menus: buildMacosPlatformMenus(
          onNew: _clearCanvas,
          onOpen: _openCanvas,
          onSave: _saveCanvas,
          onSaveAs: _saveCanvasAs,
          onSelectAll: _selectAll,
          onDeselect: _deselect,
          onInvertSelection: _invertSelection,
          onDeleteSelection: _deleteSelection,
          hasSelection: _selection != null,
        ),
        child: body,
      );
    }

    return body;
  }
}
