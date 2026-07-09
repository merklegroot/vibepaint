import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/menus/platform_file_menus.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/formats/openraster/openraster_io.dart';
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/models/layer_stack.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/models/stroke.dart';
import 'package:vibepaint/models/text_run.dart';
import 'package:vibepaint/painters/canvas_painter.dart';
import 'package:vibepaint/painters/rotate_overlay_painter.dart';
import 'package:vibepaint/painters/selection_overlay_painter.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/theme/color_wells.dart';
import 'package:vibepaint/utils/ai_enhance.dart';
import 'package:vibepaint/widgets/adjustment_dialog.dart';
import 'package:vibepaint/widgets/ai_enhance_preview_dialog.dart';
import 'package:vibepaint/widgets/ai_enhance_progress_dialog.dart';
import 'package:vibepaint/widgets/ai_enhance_settings_dialog.dart';
import 'package:vibepaint/utils/canvas_clipboard.dart';
import 'package:vibepaint/utils/canvas_file_dialogs.dart';
import 'package:vibepaint/utils/canvas_geometry.dart';
import 'package:vibepaint/utils/canvas_image_io.dart';
import 'package:vibepaint/utils/canvas_pointer_input.dart';
import 'package:vibepaint/utils/canvas_viewport.dart';
import 'package:vibepaint/utils/document_title.dart';
import 'package:vibepaint/utils/flood_fill.dart';
import 'package:vibepaint/utils/image_adjustments.dart';
import 'package:vibepaint/utils/image_artistic_effects.dart';
import 'package:vibepaint/utils/image_blur_effects.dart';
import 'package:vibepaint/utils/image_color_effects.dart';
import 'package:vibepaint/utils/image_distort_effects.dart';
import 'package:vibepaint/utils/image_photo_effects.dart';
import 'package:vibepaint/utils/image_render_effects.dart';
import 'package:vibepaint/utils/image_stylize_effects.dart';
import 'package:vibepaint/utils/image_transforms.dart';
import 'package:vibepaint/utils/layer_fill_ops.dart';
import 'package:vibepaint/utils/selection_clipboard_ops.dart';
import 'package:vibepaint/utils/layer_stack_adjustments.dart';
import 'package:vibepaint/utils/layer_stack_image_ops.dart';
import 'package:vibepaint/utils/native_window_title.dart';
import 'package:vibepaint/utils/selection_cursors.dart';
import 'package:vibepaint/utils/selection_geometry.dart';
import 'package:vibepaint/utils/selection_handles.dart';
import 'package:vibepaint/widgets/app_menu_bar.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';
import 'package:vibepaint/widgets/canvas_text_editor.dart';
import 'package:vibepaint/widgets/color_palette_panel.dart';
import 'package:vibepaint/widgets/history_panel.dart';
import 'package:vibepaint/widgets/color_picker_dialog.dart';
import 'package:vibepaint/widgets/dithering_dialog.dart';
import 'package:vibepaint/widgets/render_effects_dialog.dart';
import 'package:vibepaint/widgets/layers_panel.dart';
import 'package:vibepaint/widgets/new_image_dialog.dart';
import 'package:vibepaint/widgets/offset_selection_dialog.dart';
import 'package:vibepaint/widgets/paint_toolbar.dart';
import 'package:vibepaint/widgets/resize_dimensions_dialog.dart';
import 'package:vibepaint/widgets/rotate_angle_dialog.dart';
import 'package:vibepaint/widgets/save_image_dialog.dart';
import 'package:vibepaint/widgets/text_tool_options_control.dart';
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
  late Color _primaryColor;
  late Color _gradientEndColor;
  double _brushSize = 6;
  PaintTool _activeTool = PaintTool.brush;
  ShapeStyle _shapeStyle = ShapeStyle.outline;
  Size _documentSize = Size.zero;
  String? _documentPath;
  int _editGeneration = 0;
  int _savedGeneration = 0;
  ColorWellTarget _colorTarget = ColorWellTarget.primary;
  CanvasSelection? _selection;
  CanvasSelection? _selectionDraft;
  Offset? _selectionDragStart;
  List<Offset>? _lassoPoints;
  bool _movingSelection = false;
  bool _aiEnhanceBusy = false;
  Offset? _moveStart;
  List<Stroke>? _strokesBeforeMove;
  CanvasSelection? _selectionBeforeMove;
  bool _resizingSelection = false;
  SelectionResizeHandle? _resizeHandle;
  Rect? _resizeOriginalBounds;
  MouseCursor _canvasCursor = MouseCursor.defer;
  late final AnimationController _marchingAntsController;
  final Set<int> _canvasPointers = {};
  int? _drawingPointer;
  Uint8List? _eyedropperPixelData;
  int _eyedropperImageWidth = 0;
  int _eyedropperImageHeight = 0;
  CanvasViewport _viewport = const CanvasViewport();
  Size _viewportSize = Size.zero;
  int? _viewportPanPointer;
  Offset? _viewportPanAnchor;
  Offset? _viewportPanAtStart;
  double? _panZoomStartScale;
  Offset? _panZoomFocal;
  TextRun? _textDraft;
  TextToolOptions _textOptions = const TextToolOptions();
  bool _freeRotateActive = false;
  bool _angleRotateActive = false;
  double _rotatePreviewAngle = 0;
  double? _rotateStartAngle;
  Offset? _rotateDragPosition;

  bool get _rotatePreviewActive => _freeRotateActive || _angleRotateActive;

  String? get _rotateToolbarLabel {
    if (_freeRotateActive) {
      return 'Free Rotate';
    }
    if (_angleRotateActive) {
      return 'Rotate';
    }
    return null;
  }

  Offset? get _rotateOverlayDragPosition {
    if (_freeRotateActive) {
      return _rotateDragPosition;
    }
    if (_angleRotateActive && _rotatePreviewAngle != 0) {
      return _canvasCenter +
          Offset.fromDirection(_rotatePreviewAngle, RotateOverlayPainter.guideRadius);
    }
    return null;
  }

  bool get _isDirty => _editGeneration != _savedGeneration;

  Offset get _canvasCenter =>
      Offset(_documentSize.width / 2, _documentSize.height / 2);

  bool get _shiftPressed => HardwareKeyboard.instance.isShiftPressed;

  bool get _altPressed => HardwareKeyboard.instance.isAltPressed;

  bool get _spacePressed =>
      HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space);

  bool get _subtractSelectionModifier =>
      HardwareKeyboard.instance.isControlPressed;

  @override
  void initState() {
    super.initState();
    _layerStack = LayerStack(initialStrokes: widget.initialStrokes);
    _primaryColor = AppColors.presetColors[widget.initialColorIndex];
    _gradientEndColor = AppColors.presetColors[0];
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
    _clearEyedropperCache();
    _marchingAntsController.dispose();
    _layerStack.dispose();
    super.dispose();
  }

  int? get _primaryPresetIndex => presetColorIndex(_primaryColor);

  bool get _isErasing => _activeTool == PaintTool.eraser;

  bool get _isPencil => _activeTool == PaintTool.pencil;

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
        _primaryColor = AppColors.presetColors[defaultPrimaryColorIndex];
      } else {
        _primaryColor = canvas;
      }
    });
    _noteDocumentEdited();
  }

  void _resetColors() {
    setState(() {
      _primaryColor = AppColors.presetColors[defaultPrimaryColorIndex];
      _layerStack.setBackgroundColor(defaultCanvasBackground);
    });
    _noteDocumentEdited();
  }

  Future<void> _openColorPicker(ColorWellTarget target) async {
    final result = await showDialog<ColorPickerResult>(
      context: context,
      builder: (context) => ColorPickerDialog(
        primaryColor: _primaryColor,
        secondaryColor: _layerStack.backgroundColor,
        editingTarget: target,
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _primaryColor = result.primary;
      _layerStack.setBackgroundColor(result.secondary);
      _colorTarget = target;
    });
    if (_textDraft != null) {
      _syncTextDraftStyleFromToolbar();
    }
    _noteDocumentEdited();
  }

  Future<void> _pickGradientEndColor() async {
    final result = await showDialog<ColorPickerResult>(
      context: context,
      builder: (context) => ColorPickerDialog(
        primaryColor: _gradientEndColor,
        secondaryColor: _layerStack.backgroundColor,
        editingTarget: ColorWellTarget.primary,
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() => _gradientEndColor = result.primary);
  }

  String get _statusHint {
    if (_freeRotateActive) {
      final degrees = (_rotatePreviewAngle * 180 / math.pi).round();
      return 'Free Rotate · Drag to set angle · $degrees° · Esc: cancel';
    }

    if (_angleRotateActive) {
      final degrees = (_rotatePreviewAngle * 180 / math.pi).round();
      return 'Rotate · $degrees° · Adjust angle in dialog';
    }

    if (_activeTool.isMoveTool) {
      if (_selection != null) {
        return 'Drag inside selection to move pixels';
      }
      return 'Select an area first';
    }

    if (_activeTool.isSelectionTool) {
      final hints = <String>[
        _activeTool == PaintTool.lassoSelect
            ? 'Draw around area to select'
            : 'Drag to select',
      ];
      if (_selection != null) {
        hints.add('Drag inside to move');
      }
      hints.add('Shift: add');
      hints.add('Ctrl: subtract');
      if (_selection?.canReshape ?? false) {
        hints.add('Drag handles to resize');
      }
      return hints.join(' · ');
    }

    if (_activeTool == PaintTool.eyedropper) {
      return 'Click or drag to sample a color';
    }

    if (_activeTool == PaintTool.fillBucket) {
      return 'Click to fill · Tolerance uses brush size';
    }

    if (_activeTool == PaintTool.magicWand) {
      return 'Click to select by color · Shift: add · Ctrl: subtract';
    }

    if (_activeTool == PaintTool.text) {
      if (_textDraft != null) {
        return 'Type text · Enter: finish · Shift+Enter: new line · Esc: cancel';
      }
      return 'Click to place text · Font tools control family, size, style, and alignment';
    }

    if (_activeTool == PaintTool.gradient) {
      return 'Drag to set gradient direction · Shift: 45°';
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

  String get _viewportHint =>
      'Scroll: zoom · Space+drag or middle-drag: pan · $platformZoomKeyboardHint';

  bool _shouldViewportPan(PointerDownEvent event) {
    return _spacePressed || (event.buttons & kMiddleMouseButton) != 0;
  }

  void _resetViewport() {
    _viewport = const CanvasViewport();
    _viewportPanPointer = null;
    _viewportPanAnchor = null;
    _viewportPanAtStart = null;
    _panZoomStartScale = null;
    _panZoomFocal = null;
  }

  void _setViewport(CanvasViewport viewport) {
    setState(() => _viewport = viewport);
  }

  void _zoomAt(Offset viewportFocal, double factor) {
    _setViewport(_viewport.zoomByAt(viewportFocal, factor));
  }

  void _zoomToActualSize() {
    setState(_resetViewport);
  }

  void _fitCanvasToWindow() {
    if (_viewportSize == Size.zero || _documentSize == Size.zero) {
      return;
    }
    _setViewport(
      const CanvasViewport().fitToWindow(_viewportSize, _documentSize),
    );
  }

  void _zoomInFromCenter() {
    if (_viewportSize == Size.zero) {
      return;
    }
    _zoomAt(
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
      CanvasViewport.scrollZoomFactor,
    );
  }

  void _zoomOutFromCenter() {
    if (_viewportSize == Size.zero) {
      return;
    }
    _zoomAt(
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
      1 / CanvasViewport.scrollZoomFactor,
    );
  }

  bool _isInsideCanvas(Offset position, Rect bounds) {
    return isInsideCanvas(position, bounds.width, bounds.height);
  }

  void _setCanvasCursor(MouseCursor cursor, {SelectionResizeHandle? handle}) {
    if (handle != null) {
      SelectionCursors.applyForHandle(handle);
      cursor = SelectionCursors.mouseCursorFor(handle);
    } else {
      SelectionCursors.clearNativeOverride();
    }

    if (_canvasCursor == cursor) {
      return;
    }
    setState(() => _canvasCursor = cursor);
  }

  void _resetCanvasCursor() {
    SelectionCursors.clearNativeOverride();
    _setCanvasCursor(MouseCursor.defer);
  }

  void _updateCanvasCursor(Offset position) {
    if (_viewportPanPointer != null) {
      _setCanvasCursor(SystemMouseCursors.grabbing);
      return;
    }

    if (_freeRotateActive || _angleRotateActive) {
      _setCanvasCursor(SystemMouseCursors.grabbing);
      return;
    }

    if (_spacePressed) {
      _setCanvasCursor(SystemMouseCursors.grab);
      return;
    }

    if (_resizingSelection && _resizeHandle != null) {
      _setCanvasCursor(
        SelectionCursors.mouseCursorFor(_resizeHandle!),
        handle: _resizeHandle,
      );
      return;
    }

    if (_activeTool.isMoveTool) {
      if (_selection != null && _selection!.contains(position)) {
        _setCanvasCursor(SystemMouseCursors.move);
        return;
      }
      _setCanvasCursor(SystemMouseCursors.precise);
      return;
    }

    if (_activeTool.isSelectionTool) {
      if (_selection?.canReshape == true && _selectionDraft == null) {
        final handle = hitTestSelectionHandle(position, _selection!.bounds);
        if (handle != null) {
          _setCanvasCursor(
            SelectionCursors.mouseCursorFor(handle),
            handle: handle,
          );
          return;
        }
      }

      if (_selection != null && _selection!.contains(position)) {
        SelectionCursors.clearNativeOverride();
        _setCanvasCursor(SystemMouseCursors.move);
        return;
      }

      if (_activeTool == PaintTool.lassoSelect) {
        _setCanvasCursor(SystemMouseCursors.precise);
        return;
      }
    }

    if (_activeTool == PaintTool.eyedropper ||
        _activeTool == PaintTool.fillBucket ||
        _activeTool == PaintTool.magicWand ||
        _activeTool == PaintTool.text) {
      _setCanvasCursor(SystemMouseCursors.precise);
      return;
    }

    _resetCanvasCursor();
  }

  SelectionShape get _activeSelectionShape =>
      _activeTool == PaintTool.ellipseSelect
          ? SelectionShape.ellipse
          : SelectionShape.rectangle;

  CanvasSelection? get _activeSelectionOverlay =>
      _selectionDraft ?? _selection;

  bool get _hasSelection =>
      _selection != null && !_selection!.isEmpty;

  bool get _canClipboardCopy => _hasSelection;

  bool get _canClipboardPaste => CanvasClipboard.hasData;

  bool get _canDeselect =>
      _selection != null || _selectionDraft != null;

  void _selectAll() {
    if (_documentSize == Size.zero) {
      return;
    }
    setState(() {
      _selection = CanvasSelection.all(_documentSize);
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
      _lassoPoints = null;
      _movingSelection = false;
      _moveStart = null;
      _strokesBeforeMove = null;
      _selectionBeforeMove = null;
      _resizingSelection = false;
      _resizeHandle = null;
      _resizeOriginalBounds = null;
      _resetCanvasCursor();
    });
  }

  void _changeSelectionShape(SelectionShape shape) {
    if (_selection == null || !_selection!.canReshape) {
      return;
    }
    if (_selection!.shape == shape) {
      return;
    }

    setState(() {
      _selection = _selection!.withShape(shape);
      _activeTool = shape == SelectionShape.rectangle
          ? PaintTool.rectSelect
          : PaintTool.ellipseSelect;
    });
  }

  void _applySelectionTool(PaintTool tool) {
    if (_textDraft != null && tool != PaintTool.text) {
      _commitTextDraft();
    }
    setState(() {
      if (tool.isBoxSelectionTool &&
          _selection?.canReshape == true &&
          _selectionDraft == null) {
        final shape = tool == PaintTool.rectSelect
            ? SelectionShape.rectangle
            : SelectionShape.ellipse;
        if (_selection!.shape != shape) {
          _selection = _selection!.withShape(shape);
        }
      }
      _activeTool = tool;
    });
  }

  void _beginTextEditing(Offset position, Rect bounds) {
    if (!_isInsideCanvas(position, bounds) || _documentSize == Size.zero) {
      return;
    }

    if (_textDraft != null) {
      final boundsBox = _textDraft!.bounds();
      if (boundsBox.inflate(8).contains(position)) {
        return;
      }
      _commitTextDraft();
    }

    setState(() {
      _textDraft = TextRun(
        text: '',
        position: position,
        color: _primaryColor,
        fontSize: _textOptions.fontSize,
        fontFamily: _textOptions.fontFamily,
        bold: _textOptions.bold,
        italic: _textOptions.italic,
        underline: _textOptions.underline,
        align: _textOptions.align,
      );
    });
  }

  void _updateTextDraft(TextRun draft) {
    setState(() => _textDraft = draft);
  }

  void _commitTextDraft() {
    final draft = _textDraft;
    if (draft == null) {
      return;
    }

    setState(() {
      _textDraft = null;
      if (!draft.isEmpty) {
        _layerStack.activeHistory.add(
          Stroke(
            color: draft.color,
            brushSize: draft.fontSize,
            shape: StrokeShape.text,
            points: [draft.position],
            textRun: draft,
          ),
        );
        _noteDocumentEdited();
      }
    });
  }

  void _cancelTextDraft() {
    if (_textDraft == null) {
      return;
    }
    setState(() => _textDraft = null);
  }

  void _syncTextDraftStyleFromToolbar() {
    final draft = _textDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _textDraft = draft.copyWith(
        color: _primaryColor,
        fontSize: _textOptions.fontSize,
        fontFamily: _textOptions.fontFamily,
        clearFontFamily: _textOptions.fontFamily == null,
        bold: _textOptions.bold,
        italic: _textOptions.italic,
        underline: _textOptions.underline,
        align: _textOptions.align,
      );
    });
  }

  void _onTextOptionsChanged(TextToolOptions options) {
    setState(() => _textOptions = options);
    _syncTextDraftStyleFromToolbar();
  }

  void _invertSelection() {
    if (_selection == null || _documentSize == Size.zero) {
      return;
    }
    setState(() {
      _selection = _selection!.inverted(_documentSize);
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
        label: 'Delete selection',
      );
    });
    _noteDocumentEdited();
  }

  bool get _canCropToSelection =>
      _selection != null && !_selection!.isEmpty && _documentSize != Size.zero;

  Future<void> _applyCropRect(Rect rect) async {
    if (_documentSize == Size.zero || rect.isEmpty) {
      return;
    }

    final currentSize = _documentSize;
    final newSize = documentSizeFromCropRect(rect);
    setState(() {
      _layerStack.cropContentToRect(rect);
      _documentSize = newSize;
    });
    await _layerStack.cropBackgroundToRect(rect, currentSize);
    _deselect();
    _noteDocumentEdited();
  }

  Future<void> _cropToSelection() async {
    final selection = _selection;
    if (selection == null || selection.isEmpty || _documentSize == Size.zero) {
      return;
    }

    final currentSize = _documentSize;
    final newSize = documentSizeFromCropRect(selection.bounds);
    setState(() {
      _layerStack.cropContentToSelection(selection);
      _documentSize = newSize;
    });
    await _layerStack.cropBackgroundToRect(selection.bounds, currentSize);
    _deselect();
    _noteDocumentEdited();
  }

  Future<void> _autoCrop() async {
    if (_documentSize == Size.zero) {
      return;
    }

    final bounds = contentBounds(
      layers: _layerStack.layers,
      canvasSize: _documentSize,
      includeBackground: _layerStack.backgroundImage != null,
    );
    if (bounds == null || bounds.isEmpty) {
      _showMessage('Nothing to crop');
      return;
    }

    await _applyCropRect(bounds);
  }

  Future<void> _resizeImage() async {
    if (_documentSize == Size.zero) {
      return;
    }

    final result = await showDialog<ResizeDimensionsResult>(
      context: context,
      builder: (context) => ResizeDimensionsDialog(
        title: 'Resize Image',
        initialWidth: _documentSize.width.ceil(),
        initialHeight: _documentSize.height.ceil(),
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    final currentSize = _documentSize;
    final newSize = Size(result.width.toDouble(), result.height.toDouble());
    setState(() {
      _layerStack.resizeImageContent(currentSize, newSize);
      _documentSize = newSize;
    });
    await _layerStack.resizeBackgroundImage(currentSize, newSize);
    _deselect();
    _noteDocumentEdited();
  }

  Future<void> _resizeCanvas() async {
    if (_documentSize == Size.zero) {
      return;
    }

    final result = await showDialog<ResizeDimensionsResult>(
      context: context,
      builder: (context) => ResizeDimensionsDialog(
        title: 'Resize Canvas',
        initialWidth: _documentSize.width.ceil(),
        initialHeight: _documentSize.height.ceil(),
        showAnchor: true,
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    final currentSize = _documentSize;
    final newSize = Size(result.width.toDouble(), result.height.toDouble());
    setState(() {
      _layerStack.resizeCanvasContent(
        currentSize: currentSize,
        newSize: newSize,
        anchor: result.anchor,
      );
      _documentSize = newSize;
    });
    _deselect();
    _noteDocumentEdited();
  }

  Future<void> _flipHorizontal() async {
    if (_documentSize == Size.zero) {
      return;
    }

    setState(() => _layerStack.flipHorizontal(_documentSize));
    await _layerStack.flipBackgroundHorizontal();
    _deselect();
    _noteDocumentEdited();
  }

  Future<void> _flipVertical() async {
    if (_documentSize == Size.zero) {
      return;
    }

    setState(() => _layerStack.flipVertical(_documentSize));
    await _layerStack.flipBackgroundVertical();
    _deselect();
    _noteDocumentEdited();
  }

  Future<void> _rotate90Clockwise() async {
    if (_documentSize == Size.zero) {
      return;
    }

    final currentSize = _documentSize;
    setState(() {
      _layerStack.rotate90Clockwise(currentSize);
      _documentSize = Size(currentSize.height, currentSize.width);
    });
    await _layerStack.rotateBackground90Clockwise();
    _deselect();
    _noteDocumentEdited();
  }

  Future<void> _rotate90CounterClockwise() async {
    if (_documentSize == Size.zero) {
      return;
    }

    final currentSize = _documentSize;
    setState(() {
      _layerStack.rotate90CounterClockwise(currentSize);
      _documentSize = Size(currentSize.height, currentSize.width);
    });
    await _layerStack.rotateBackground90CounterClockwise();
    _deselect();
    _noteDocumentEdited();
  }

  Future<void> _rotate180() async {
    if (_documentSize == Size.zero) {
      return;
    }

    setState(() => _layerStack.rotate180(_documentSize));
    await _layerStack.rotateBackground180();
    _deselect();
    _noteDocumentEdited();
  }

  void _beginFreeRotate() {
    if (_documentSize == Size.zero) {
      return;
    }

    if (_textDraft != null) {
      _commitTextDraft();
    }
    if (_currentStroke != null) {
      setState(_commitCurrentStroke);
    }

    setState(() {
      _freeRotateActive = true;
      _angleRotateActive = false;
      _rotatePreviewAngle = 0;
      _rotateStartAngle = null;
      _rotateDragPosition = null;
      _deselect();
    });
  }

  Future<void> _prepareForRotate() async {
    if (_textDraft != null) {
      _commitTextDraft();
    }
    if (_currentStroke != null) {
      setState(_commitCurrentStroke);
    }
    _deselect();
  }

  Future<void> _showRotateAngleDialog() async {
    if (_documentSize == Size.zero) {
      return;
    }

    await _prepareForRotate();

    if (!mounted) {
      return;
    }

    setState(() {
      _freeRotateActive = false;
      _angleRotateActive = true;
      _rotatePreviewAngle = 0;
      _rotateStartAngle = null;
      _rotateDragPosition = null;
    });

    final result = await showDialog<double>(
      context: context,
      builder: (context) => RotateAngleDialog(
        onAngleChanged: (degrees) {
          if (!mounted) {
            return;
          }
          setState(() {
            _rotatePreviewAngle = degrees * math.pi / 180;
          });
        },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _angleRotateActive = false;
      _rotatePreviewAngle = 0;
    });

    if (result == null || result.abs() < 0.001) {
      return;
    }

    final angle = result * math.pi / 180;
    setState(() => _layerStack.rotateContent(_documentSize, angle));
    await _layerStack.rotateBackgroundByDegrees(result);
    _noteDocumentEdited();
  }

  void _cancelFreeRotate() {
    if (!_freeRotateActive) {
      return;
    }

    setState(() {
      _freeRotateActive = false;
      _rotatePreviewAngle = 0;
      _rotateStartAngle = null;
      _rotateDragPosition = null;
    });
    _resetCanvasCursor();
  }

  void _beginRotateDrag(Offset position) {
    _rotateStartAngle = angleFromCenter(position, _canvasCenter);
    _rotateDragPosition = position;
  }

  void _extendRotateDrag(Offset position) {
    if (_rotateStartAngle == null) {
      return;
    }

    final currentAngle = angleFromCenter(position, _canvasCenter);
    setState(() {
      _rotatePreviewAngle = currentAngle - _rotateStartAngle!;
      _rotateDragPosition = position;
    });
  }

  Future<void> _endRotateDrag() async {
    if (!_freeRotateActive) {
      return;
    }

    final angle = _rotatePreviewAngle;
    _rotateStartAngle = null;
    _rotateDragPosition = null;

    if (angle.abs() < 0.001) {
      _cancelFreeRotate();
      return;
    }

    setState(() {
      _layerStack.rotateContent(_documentSize, angle);
      _freeRotateActive = false;
      _rotatePreviewAngle = 0;
    });
    await _layerStack.rotateBackgroundByDegrees(angle * 180 / math.pi);
    _resetCanvasCursor();
    _noteDocumentEdited();
  }

  void _flattenImage() {
    if (_layerStack.layers.length <= 1) {
      return;
    }

    setState(_layerStack.flattenLayers);
    _noteDocumentEdited();
  }

  bool _ensureActiveLayerAdjustable() {
    if (_documentSize == Size.zero) {
      return false;
    }
    if (!_layerStack.activeLayerHasAdjustableContent) {
      _showMessage('Nothing to adjust on the active layer');
      return false;
    }
    return true;
  }

  Future<void> _applyInstantAdjustment(
    String label,
    img.Image Function(img.Image source) transform,
  ) async {
    if (!_ensureActiveLayerAdjustable()) {
      return;
    }

    setState(() {});
    await _layerStack.applyActiveLayerAdjustment(
      _documentSize,
      transform,
      historyLabel: label,
    );
    _noteDocumentEdited();
  }

  Future<bool> _runAdjustmentDialog({
    required String title,
    required List<AdjustmentSliderSpec> sliders,
    required img.Image Function(img.Image source, List<double> values) apply,
    String? footer,
  }) async {
    if (!_ensureActiveLayerAdjustable()) {
      return false;
    }

    final source = await _layerStack.captureActiveLayerRaster(_documentSize);
    if (source == null || !mounted) {
      return false;
    }

    Future<void> preview(List<double> values) async {
      final result = apply(source, values);
      await _layerStack.replaceActiveLayerWithRaster(
        size: _documentSize,
        raster: result,
      );
      if (mounted) {
        setState(() {});
      }
    }

    final result = await showDialog<List<double>>(
      context: context,
      builder: (context) => AdjustmentDialog(
        title: title,
        sliders: sliders,
        footer: footer,
        onValuesChanged: preview,
      ),
    );

    if (!mounted) {
      return false;
    }

    if (result == null) {
      _layerStack.activeHistory.clearPreview();
      setState(() {});
      return false;
    }

    await preview(result);
    _layerStack.activeHistory.commitStrokes(
      title,
      _layerStack.activeHistory.strokes,
    );
    return true;
  }

  Future<void> _autoLevel() => _applyInstantAdjustment('Auto level', autoLevel);

  Future<void> _blackAndWhite() =>
      _applyInstantAdjustment('Black and white', blackAndWhite);

  Future<void> _invertColors() =>
      _applyInstantAdjustment('Invert colors', invertColors);

  Future<void> _sepia() => _applyInstantAdjustment('Sepia', applySepia);

  Future<void> _brightnessContrast() async {
    final applied = await _runAdjustmentDialog(
      title: 'Brightness / Contrast',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Brightness',
          min: 0,
          max: 200,
          initial: 100,
          divisions: 200,
        ),
        AdjustmentSliderSpec(
          label: 'Contrast',
          min: 0,
          max: 200,
          initial: 100,
          divisions: 200,
        ),
      ],
      footer: '100 is neutral. Preview updates on the canvas.',
      apply: (source, values) => applyBrightnessContrast(
        source,
        brightness: uiBrightnessToFilter(values[0].round()),
        contrast: uiContrastToFilter(values[1].round()),
      ),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _curves() async {
    final applied = await _runAdjustmentDialog(
      title: 'Curves',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Gamma',
          min: 0.1,
          max: 3,
          initial: 1,
          divisions: 29,
        ),
      ],
      footer: 'Lower values lighten midtones; higher values darken them.',
      apply: (source, values) => applyCurves(source, gamma: values[0]),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _hueSaturation() async {
    final applied = await _runAdjustmentDialog(
      title: 'Hue / Saturation',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Hue',
          min: -180,
          max: 180,
          initial: 0,
          divisions: 360,
          suffix: '°',
        ),
        AdjustmentSliderSpec(
          label: 'Saturation',
          min: 0,
          max: 200,
          initial: 100,
          divisions: 200,
        ),
      ],
      apply: (source, values) => applyHueSaturation(
        source,
        hue: values[0],
        saturation: uiSaturationToFilter(values[1].round()),
      ),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _levels() async {
    final applied = await _runAdjustmentDialog(
      title: 'Levels',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Input black',
          min: 0,
          max: 255,
          initial: 0,
          divisions: 255,
        ),
        AdjustmentSliderSpec(
          label: 'Input white',
          min: 0,
          max: 255,
          initial: 255,
          divisions: 255,
        ),
        AdjustmentSliderSpec(
          label: 'Gamma',
          min: 0.1,
          max: 3,
          initial: 1,
          divisions: 29,
        ),
      ],
      apply: (source, values) => applyLevels(
        source,
        inputBlack: values[0].round(),
        inputWhite: values[1].round(),
        gamma: values[2],
      ),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _posterize() async {
    final applied = await _runAdjustmentDialog(
      title: 'Posterize',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Color levels',
          min: 2,
          max: 256,
          initial: 8,
          divisions: 254,
        ),
      ],
      apply: (source, values) =>
          applyPosterize(source, levels: values[0].round()),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _inkSketch() async {
    final applied = await _runAdjustmentDialog(
      title: 'Ink Sketch',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Amount',
          min: 0,
          max: 100,
          initial: 100,
          divisions: 100,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) => inkSketch(source, amount: values[0]),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _oilPainting() async {
    final applied = await _runAdjustmentDialog(
      title: 'Oil Painting',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Amount',
          min: 0,
          max: 100,
          initial: 80,
          divisions: 100,
        ),
        AdjustmentSliderSpec(
          label: 'Brush size',
          min: 1,
          max: 20,
          initial: 8,
          divisions: 19,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) => oilPainting(
        source,
        amount: values[0],
        brushSize: values[1],
      ),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _pencilSketch() async {
    final applied = await _runAdjustmentDialog(
      title: 'Pencil Sketch',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Amount',
          min: 0,
          max: 100,
          initial: 100,
          divisions: 100,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) => pencilSketch(source, amount: values[0]),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _fragmentBlur() async {
    final applied = await _runAdjustmentDialog(
      title: 'Fragment',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Fragment size',
          min: 4,
          max: 64,
          initial: 16,
          divisions: 60,
        ),
        AdjustmentSliderSpec(
          label: 'Distance',
          min: 0,
          max: 40,
          initial: 12,
          divisions: 40,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) => fragmentEffect(
        source,
        fragmentSize: values[0],
        distance: values[1],
      ),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _gaussianBlur() async {
    final applied = await _runAdjustmentDialog(
      title: 'Gaussian Blur',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Radius',
          min: 0,
          max: 40,
          initial: 8,
          divisions: 40,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) =>
          gaussianBlurEffect(source, radius: values[0]),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _motionBlur() async {
    final applied = await _runAdjustmentDialog(
      title: 'Motion Blur',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Angle',
          min: 0,
          max: 360,
          initial: 0,
          divisions: 360,
          suffix: '°',
        ),
        AdjustmentSliderSpec(
          label: 'Distance',
          min: 0,
          max: 60,
          initial: 20,
          divisions: 60,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) => motionBlurEffect(
        source,
        angle: values[0],
        distance: values[1],
      ),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _radialBlur() async {
    final applied = await _runAdjustmentDialog(
      title: 'Radial Blur',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Amount',
          min: 0,
          max: 100,
          initial: 50,
          divisions: 100,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) =>
          radialBlurEffect(source, amount: values[0]),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _unfocusBlur() async {
    final applied = await _runAdjustmentDialog(
      title: 'Unfocus',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Amount',
          min: 0,
          max: 100,
          initial: 50,
          divisions: 100,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) => unfocusEffect(source, amount: values[0]),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _zoomBlur() async {
    final applied = await _runAdjustmentDialog(
      title: 'Zoom Blur',
      sliders: const [
        AdjustmentSliderSpec(
          label: 'Amount',
          min: 0,
          max: 100,
          initial: 50,
          divisions: 100,
        ),
      ],
      footer: 'Preview updates on the canvas.',
      apply: (source, values) => zoomBlurEffect(source, amount: values[0]),
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _dithering() async {
    if (!_ensureActiveLayerAdjustable()) {
      return;
    }

    final source = await _layerStack.captureActiveLayerRaster(_documentSize);
    if (source == null || !mounted) {
      return;
    }

    Future<void> preview(DitheringSettings settings) async {
      final result = ditheringEffect(
        source,
        colorLevels: settings.colorLevels,
        kernel: settings.kernel,
        serpentine: settings.serpentine,
      );
      await _layerStack.replaceActiveLayerWithRaster(
        size: _documentSize,
        raster: result,
      );
      if (mounted) {
        setState(() {});
      }
    }

    final result = await showDialog<DitheringSettings>(
      context: context,
      builder: (context) => DitheringDialog(
        onSettingsChanged: preview,
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      _layerStack.activeHistory.clearPreview();
      setState(() {});
      return;
    }

    await preview(result);
    _layerStack.activeHistory.commitStrokes(
      'Dithering',
      _layerStack.activeHistory.strokes,
    );
    _noteDocumentEdited();
  }

  Future<void> _applySliderEffect({
    required String title,
    required List<AdjustmentSliderSpec> sliders,
    required img.Image Function(img.Image source, List<double> values) apply,
  }) async {
    final applied = await _runAdjustmentDialog(
      title: title,
      sliders: sliders,
      footer: 'Preview updates on the canvas.',
      apply: apply,
    );
    if (applied) {
      _noteDocumentEdited();
    }
  }

  Future<void> _glow() => _applySliderEffect(
        title: 'Glow',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Radius',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
          AdjustmentSliderSpec(
            label: 'Brightness',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
          AdjustmentSliderSpec(
            label: 'Contrast',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
        ],
        apply: (source, values) => glowEffect(
          source,
          radius: values[0],
          brightness: values[1],
          contrast: values[2],
        ),
      );

  Future<void> _sharpen() => _applySliderEffect(
        title: 'Sharpen',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Amount',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
        ],
        apply: (source, values) => sharpenEffect(source, amount: values[0]),
      );

  Future<void> _softenPortrait() => _applySliderEffect(
        title: 'Soften Portrait',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Softness',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
          AdjustmentSliderSpec(
            label: 'Lighting',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
          AdjustmentSliderSpec(
            label: 'Warmth',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
        ],
        apply: (source, values) => softenPortraitEffect(
          source,
          softness: values[0],
          lighting: values[1],
          warmth: values[2],
        ),
      );

  Future<void> _bulge() => _applySliderEffect(
        title: 'Bulge',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Amount',
            min: 0,
            max: 100,
            initial: 60,
            divisions: 100,
          ),
        ],
        apply: (source, values) => bulgeEffect(source, amount: values[0]),
      );

  Future<void> _frostedGlass() => _applySliderEffect(
        title: 'Frosted Glass',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Amount',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
        ],
        apply: (source, values) =>
            frostedGlassEffect(source, amount: values[0]),
      );

  Future<void> _pixelate() => _applySliderEffect(
        title: 'Pixelate',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Cell size',
            min: 2,
            max: 64,
            initial: 12,
            divisions: 62,
          ),
        ],
        apply: (source, values) => pixelateEffect(source, cellSize: values[0]),
      );

  Future<void> _polarInversion() => _applySliderEffect(
        title: 'Polar Inversion',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Amount',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
        ],
        apply: (source, values) =>
            polarInversionEffect(source, amount: values[0]),
      );

  Future<void> _tileReflection() => _applySliderEffect(
        title: 'Tile Reflection',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Rotation',
            min: 0,
            max: 360,
            initial: 0,
            divisions: 360,
            suffix: '°',
          ),
          AdjustmentSliderSpec(
            label: 'Tile size',
            min: 4,
            max: 80,
            initial: 20,
            divisions: 76,
          ),
          AdjustmentSliderSpec(
            label: 'Intensity',
            min: 0,
            max: 100,
            initial: 60,
            divisions: 100,
          ),
        ],
        apply: (source, values) => tileReflectionEffect(
          source,
          rotation: values[0],
          tileSize: values[1],
          intensity: values[2],
        ),
      );

  Future<void> _twist() => _applySliderEffect(
        title: 'Twist',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Amount',
            min: -100,
            max: 100,
            initial: 30,
            divisions: 200,
          ),
          AdjustmentSliderSpec(
            label: 'Antialias',
            min: 0,
            max: 100,
            initial: 70,
            divisions: 100,
          ),
        ],
        apply: (source, values) => twistEffect(
          source,
          amount: values[0],
          antialias: values[1],
        ),
      );

  Future<void> _juliaFractal() => _applySliderEffect(
        title: 'Julia Fractal',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Factor',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
          AdjustmentSliderSpec(
            label: 'Quality',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
          AdjustmentSliderSpec(
            label: 'Zoom',
            min: 0,
            max: 100,
            initial: 50,
            divisions: 100,
          ),
        ],
        apply: (source, values) => juliaFractalEffect(
          source,
          factor: values[0],
          quality: values[1],
          zoom: values[2],
          primaryColor: _primaryColor,
          secondaryColor: _gradientEndColor,
        ),
      );

  Future<void> _edgeDetect() => _applySliderEffect(
        title: 'Edge Detect',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Angle',
            min: 0,
            max: 360,
            initial: 0,
            divisions: 360,
            suffix: '°',
          ),
        ],
        apply: (source, values) =>
            edgeDetectEffect(source, angle: values[0]),
      );

  Future<void> _emboss() => _applySliderEffect(
        title: 'Emboss',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Angle',
            min: 0,
            max: 360,
            initial: 45,
            divisions: 360,
            suffix: '°',
          ),
        ],
        apply: (source, values) => embossEffect(source, angle: values[0]),
      );

  Future<void> _outline() => _applySliderEffect(
        title: 'Outline',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Thickness',
            min: 1,
            max: 8,
            initial: 2,
            divisions: 7,
          ),
          AdjustmentSliderSpec(
            label: 'Intensity',
            min: 0,
            max: 100,
            initial: 70,
            divisions: 100,
          ),
        ],
        apply: (source, values) => outlineEffect(
          source,
          thickness: values[0],
          intensity: values[1],
        ),
      );

  Future<void> _relief() => _applySliderEffect(
        title: 'Relief',
        sliders: const [
          AdjustmentSliderSpec(
            label: 'Angle',
            min: 0,
            max: 360,
            initial: 45,
            divisions: 360,
            suffix: '°',
          ),
        ],
        apply: (source, values) => reliefEffect(source, angle: values[0]),
      );

  Future<void> _clouds() async {
    if (!_ensureActiveLayerAdjustable()) {
      return;
    }

    final source = await _layerStack.captureActiveLayerRaster(_documentSize);
    if (source == null || !mounted) {
      return;
    }

    Future<void> preview(CloudsSettings settings) async {
      final result = cloudsEffect(
        source,
        scale: settings.scale,
        power: settings.power,
        seed: settings.seed,
        primaryColor: _primaryColor,
        secondaryColor: _gradientEndColor,
      );
      await _layerStack.replaceActiveLayerWithRaster(
        size: _documentSize,
        raster: result,
      );
      if (mounted) {
        setState(() {});
      }
    }

    final result = await showDialog<CloudsSettings>(
      context: context,
      builder: (context) => CloudsDialog(onSettingsChanged: preview),
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      _layerStack.activeHistory.clearPreview();
      setState(() {});
      return;
    }

    await preview(result);
    _layerStack.activeHistory.commitStrokes(
      'Clouds',
      _layerStack.activeHistory.strokes,
    );
    _noteDocumentEdited();
  }

  Future<void> _mandelbrotFractal() async {
    if (!_ensureActiveLayerAdjustable()) {
      return;
    }

    final source = await _layerStack.captureActiveLayerRaster(_documentSize);
    if (source == null || !mounted) {
      return;
    }

    Future<void> preview(MandelbrotSettings settings) async {
      final result = mandelbrotFractalEffect(
        source,
        factor: settings.factor,
        quality: settings.quality,
        zoom: settings.zoom,
        primaryColor: _primaryColor,
        secondaryColor: _gradientEndColor,
        invert: settings.invert,
      );
      await _layerStack.replaceActiveLayerWithRaster(
        size: _documentSize,
        raster: result,
      );
      if (mounted) {
        setState(() {});
      }
    }

    final result = await showDialog<MandelbrotSettings>(
      context: context,
      builder: (context) => MandelbrotDialog(onSettingsChanged: preview),
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      _layerStack.activeHistory.clearPreview();
      setState(() {});
      return;
    }

    await preview(result);
    _layerStack.activeHistory.commitStrokes(
      'Mandelbrot Fractal',
      _layerStack.activeHistory.strokes,
    );
    _noteDocumentEdited();
  }

  Future<void> _copySelection({required bool merged}) async {
    if (!_hasSelection || _selection == null) {
      return;
    }

    await copySelectionToClipboard(
      documentSize: _documentSize,
      layerStack: _layerStack,
      selection: _selection!,
      merged: merged,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _cutSelection() async {
    await _copySelection(merged: false);
    _deleteSelection();
  }

  Future<void> _pasteClipboard({
    required bool intoNewLayer,
    required bool intoNewImage,
  }) async {
    final data = CanvasClipboard.data;
    if (data == null) {
      return;
    }

    if (intoNewImage) {
      final stroke = await pasteClipboardAsStroke(
        documentSize: data.size,
        pasteOrigin: Offset.zero,
      );
      if (stroke == null || !mounted) {
        return;
      }

      setState(() {
        _layerStack.clear();
        _layerStack.setBackgroundColor(defaultCanvasBackground);
        _documentSize = data.size;
        _currentStroke = null;
        _lastPanPosition = null;
        _textDraft = null;
        _selection = null;
        _selectionDraft = null;
        _layerStack.activeHistory.add(stroke, label: 'Paste');
        _resetViewport();
      });
      _resetDocumentTracking();
      _noteDocumentEdited();
      return;
    }

    if (_documentSize == Size.zero) {
      return;
    }

    final origin = intoNewLayer
        ? nextPasteOrigin(data)
        : (_selection?.bounds.topLeft ?? nextPasteOrigin(data));
    final stroke = await pasteClipboardAsStroke(
      documentSize: _documentSize,
      pasteOrigin: origin,
    );
    if (stroke == null || !mounted) {
      return;
    }

    setState(() {
      if (intoNewLayer) {
        _layerStack.addLayer();
      }
      _layerStack.activeHistory.add(stroke, label: 'Paste');
      _selection = CanvasSelection.fromRect(
        SelectionShape.rectangle,
        stroke.rasterBounds ?? Rect.fromLTWH(origin.dx, origin.dy, 1, 1),
      );
    });
    _noteDocumentEdited();
  }

  Future<void> _fillSelection() async {
    if (!_hasSelection || _selection == null) {
      return;
    }

    final stroke = await buildSelectionFillStroke(
      documentSize: _documentSize,
      selection: _selection!,
      fillColor: _primaryColor,
    );
    if (stroke == null || !mounted) {
      return;
    }

    setState(() {
      _layerStack.activeHistory.add(stroke, label: 'Fill selection');
    });
    _noteDocumentEdited();
  }

  Future<void> _offsetSelection() async {
    if (_selection == null) {
      return;
    }

    final offset = await showDialog<Offset>(
      context: context,
      builder: (context) => const OffsetSelectionDialog(),
    );
    if (offset == null || !mounted || offset == Offset.zero) {
      return;
    }

    setState(() {
      _selection = translateSelection(_selection!, offset);
    });
    _noteDocumentEdited();
  }

  void _eraseSelection() => _deleteSelection();

  void _beginResizeSelection(SelectionResizeHandle handle) {
    _resizingSelection = true;
    _resizeHandle = handle;
    _resizeOriginalBounds = _selection!.bounds;
    _setCanvasCursor(
      SelectionCursors.mouseCursorFor(handle),
      handle: handle,
    );
  }

  void _extendResizeSelection(Offset position, Rect canvasBounds) {
    if (!_resizingSelection ||
        _resizeHandle == null ||
        _resizeOriginalBounds == null ||
        _selection == null) {
      return;
    }

    setState(() {
      _selection = _selection!.withBounds(
        resizeSelectionBounds(
          original: _resizeOriginalBounds!,
          handle: _resizeHandle!,
          current: position,
          canvasBounds: canvasBounds,
          constrainSquare: _shiftPressed,
        ),
      );
    });
  }

  void _endResizeSelection() {
    _resizingSelection = false;
    _resizeHandle = null;
    _resizeOriginalBounds = null;
    _resetCanvasCursor();
  }

  void _commitSelectionDraft(CanvasSelection draft) {
    if (draft.isEmpty) {
      if (_selection != null) {
        _deselect();
      }
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

  void _beginLassoSelection(Offset position, Rect bounds) {
    if (!_isInsideCanvas(position, bounds)) {
      return;
    }

    setState(() {
      _lassoPoints = [position];
      _selectionDraft = CanvasSelection.fromPoints(
        _lassoPoints!,
        close: false,
      );
    });
  }

  void _extendLassoSelection(Offset position, Rect bounds) {
    if (_lassoPoints == null || !_isInsideCanvas(position, bounds)) {
      return;
    }

    final last = _lassoPoints!.last;
    if ((position - last).distance < 3) {
      return;
    }

    setState(() {
      _lassoPoints!.add(position);
      _selectionDraft = CanvasSelection.fromPoints(
        _lassoPoints!,
        close: false,
      );
    });
  }

  void _endLassoSelection() {
    final points = _lassoPoints;
    _lassoPoints = null;
    _selectionDraft = null;
    if (points == null) {
      return;
    }

    _commitSelectionDraft(CanvasSelection.fromPoints(points));
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
    if (draft == null) {
      return;
    }

    _commitSelectionDraft(draft);
  }

  void _beginMoveSelection(Offset position) {
    _movingSelection = true;
    _moveStart = position;
    _strokesBeforeMove = List<Stroke>.from(_layerStack.activeHistory.strokes);
    _selectionBeforeMove = _selection;
    _setCanvasCursor(SystemMouseCursors.move);
  }

  void _extendMoveSelection(Offset position) {
    if (!_movingSelection ||
        _moveStart == null ||
        _selectionBeforeMove == null ||
        _strokesBeforeMove == null) {
      return;
    }

    final delta = position - _moveStart!;
    setState(() {
      _layerStack.activeHistory.replaceStrokes(
        translateSelectedStrokes(
          _strokesBeforeMove!,
          _selectionBeforeMove!,
          delta,
        ),
      );
      _selection = translateSelection(_selectionBeforeMove!, delta);
    });
  }

  void _endMoveSelection() {
    if (!_movingSelection) {
      return;
    }

    final moved = _strokesBeforeMove != null;
    _movingSelection = false;
    _moveStart = null;
    _strokesBeforeMove = null;
    _selectionBeforeMove = null;
    _resetCanvasCursor();
    if (moved) {
      setState(() {
        _layerStack.activeHistory.commitStrokes(
          'Move selection',
          _layerStack.activeHistory.strokes,
        );
      });
      _noteDocumentEdited();
    }
  }

  void _changeBrushSize(double delta) {
    setState(() {
      _brushSize = (_brushSize + delta).clamp(
        BrushSizeControl.minSize,
        BrushSizeControl.maxSize,
      );
    });
  }

  void _clearEyedropperCache() {
    _eyedropperPixelData = null;
    _eyedropperImageWidth = 0;
    _eyedropperImageHeight = 0;
  }

  Future<void> _refreshEyedropperCache() async {
    _clearEyedropperCache();
    if (_documentSize == Size.zero) {
      return;
    }

    final rgba = await renderCanvasRgbaBytes(
      size: _documentSize,
      layers: _layerStack.layers,
      backgroundImage: _layerStack.backgroundImage,
      backgroundColor: _layerStack.backgroundColor,
    );
    if (!mounted || rgba == null) {
      return;
    }

    _eyedropperPixelData = rgba;
    _eyedropperImageWidth = _documentSize.width.ceil();
    _eyedropperImageHeight = _documentSize.height.ceil();
  }

  Future<void> _pickColorAt(Offset position, Rect bounds) async {
    if (!_isInsideCanvas(position, bounds) || _documentSize == Size.zero) {
      return;
    }

    if (_eyedropperPixelData == null) {
      await _refreshEyedropperCache();
    }

    final rgba = _eyedropperPixelData;
    if (!mounted || rgba == null) {
      return;
    }

    final color = readCanvasPixel(
      rgba: rgba,
      width: _eyedropperImageWidth,
      height: _eyedropperImageHeight,
      position: position,
    );
    if (color == null) {
      return;
    }

    setState(() {
      switch (_colorTarget) {
        case ColorWellTarget.primary:
          _primaryColor = color;
        case ColorWellTarget.canvasBackground:
          _layerStack.setBackgroundColor(color);
      }
    });
    if (_colorTarget == ColorWellTarget.canvasBackground) {
      _noteDocumentEdited();
    } else if (_textDraft != null) {
      _syncTextDraftStyleFromToolbar();
    }
  }

  Future<void> _applyFillAt(Offset position, Rect bounds) async {
    if (!_isInsideCanvas(position, bounds) || _documentSize == Size.zero) {
      return;
    }

    final stroke = await buildFillStroke(
      size: _documentSize,
      strokes: _layerStack.activeHistory.strokes,
      position: position,
      fillColor: _primaryColor,
      tolerance: floodFillToleranceFromBrushSize(_brushSize),
    );
    if (!mounted || stroke == null) {
      return;
    }

    setState(() {
      _layerStack.activeHistory.add(stroke, label: 'Fill');
    });
    _noteDocumentEdited();
  }

  Future<void> _applyMagicWandSelection(Offset position, Rect bounds) async {
    if (!_isInsideCanvas(position, bounds) || _documentSize == Size.zero) {
      return;
    }

    final selection = await buildMagicWandSelection(
      size: _documentSize,
      layers: _layerStack.layers,
      backgroundImage: _layerStack.backgroundImage,
      backgroundColor: _layerStack.backgroundColor,
      position: position,
      tolerance: floodFillToleranceFromBrushSize(_brushSize),
    );
    if (!mounted || selection == null) {
      return;
    }

    _commitSelectionDraft(selection);
  }

  void _cancelCanvasInteraction() {
    final restoringStrokes = _movingSelection ? _strokesBeforeMove : null;
    final restoringSelection = _movingSelection ? _selectionBeforeMove : null;
    setState(() {
      if (restoringStrokes != null) {
        _layerStack.activeHistory.replaceStrokes(restoringStrokes);
      }
      if (restoringSelection != null) {
        _selection = restoringSelection;
      }
      _currentStroke = null;
      _lastPanPosition = null;
      _selectionDraft = null;
      _lassoPoints = null;
      _movingSelection = false;
      _moveStart = null;
      _strokesBeforeMove = null;
      _selectionBeforeMove = null;
      _resizingSelection = false;
      _resizeHandle = null;
      _resizeOriginalBounds = null;
    });
    _viewportPanPointer = null;
    _viewportPanAnchor = null;
    _viewportPanAtStart = null;
    _panZoomStartScale = null;
    _panZoomFocal = null;
    _clearEyedropperCache();
    _resetCanvasCursor();
  }

  void _onViewportPointerSignal(PointerSignalEvent event) {
    if (_documentSize == Size.zero) {
      return;
    }

    if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy;
      if (delta == 0) {
        return;
      }

      final factor = delta < 0
          ? CanvasViewport.scrollZoomFactor
          : 1 / CanvasViewport.scrollZoomFactor;
      _zoomAt(event.localPosition, factor);
    }
  }

  void _onViewportPointerPanZoomStart(PointerPanZoomStartEvent event) {
    _panZoomStartScale = _viewport.scale;
    _panZoomFocal = event.localPosition;
  }

  void _onViewportPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (_panZoomStartScale == null || _panZoomFocal == null) {
      return;
    }

    if (event.scale == 1.0) {
      return;
    }

    final newScale = (_panZoomStartScale! * event.scale).clamp(
      CanvasViewport.minScale,
      CanvasViewport.maxScale,
    );
    _setViewport(_viewport.zoomAt(_panZoomFocal!, newScale));
  }

  void _onViewportPointerPanZoomEnd(PointerPanZoomEndEvent event) {
    _panZoomStartScale = null;
    _panZoomFocal = null;
  }

  void _syncViewportSize(Size viewportSize) {
    if (_viewportSize == viewportSize) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewportSize == viewportSize) {
        return;
      }
      setState(() => _viewportSize = viewportSize);
    });
  }

  void _onViewportPointerDown(PointerDownEvent event, Rect bounds) {
    if (_panZoomStartScale != null) {
      return;
    }

    if (_shouldViewportPan(event)) {
      _viewportPanPointer = event.pointer;
      _viewportPanAnchor = event.localPosition;
      _viewportPanAtStart = _viewport.pan;
      _setCanvasCursor(SystemMouseCursors.grabbing);
      return;
    }

    _onCanvasPointerDown(
      event,
      bounds,
      _viewport.viewportToDocument(event.localPosition),
    );
  }

  void _onViewportPointerMove(PointerMoveEvent event, Rect bounds) {
    if (_viewportPanPointer == event.pointer) {
      setState(() {
        _viewport = CanvasViewport(
          scale: _viewport.scale,
          pan: _viewportPanAtStart! + (event.localPosition - _viewportPanAnchor!),
        );
      });
      return;
    }

    if (_viewportPanPointer != null) {
      return;
    }

    _onCanvasPointerMove(
      event,
      bounds,
      _viewport.viewportToDocument(event.localPosition),
    );
  }

  void _onViewportPointerUp(PointerUpEvent event) {
    if (_viewportPanPointer == event.pointer) {
      _viewportPanPointer = null;
      _viewportPanAnchor = null;
      _viewportPanAtStart = null;
      _resetCanvasCursor();
      return;
    }

    _onCanvasPointerUp(event);
  }

  void _onViewportPointerCancel(PointerCancelEvent event) {
    if (_viewportPanPointer == event.pointer) {
      _viewportPanPointer = null;
      _viewportPanAnchor = null;
      _viewportPanAtStart = null;
      _resetCanvasCursor();
      return;
    }

    _onCanvasPointerCancel(event);
  }

  void _onCanvasPointerDown(
    PointerDownEvent event,
    Rect bounds,
    Offset position,
  ) {
    _canvasPointers.add(event.pointer);

    if (!acceptsCanvasDrawingPointer(event)) {
      if (_drawingPointer != null) {
        _cancelCanvasInteraction();
      }
      return;
    }

    if (_canvasPointers.length > 1) {
      _drawingPointer = null;
      _cancelCanvasInteraction();
      return;
    }

    _drawingPointer = event.pointer;
    _beginPan(position, bounds);
  }

  void _onCanvasPointerMove(
    PointerMoveEvent event,
    Rect bounds,
    Offset position,
  ) {
    if (_drawingPointer != event.pointer) {
      return;
    }

    if (!acceptsCanvasDrawingPointer(event)) {
      _drawingPointer = null;
      _cancelCanvasInteraction();
      return;
    }

    _extendStroke(position, bounds);
  }

  void _onCanvasPointerUp(PointerUpEvent event) {
    _canvasPointers.remove(event.pointer);
    if (_drawingPointer != event.pointer) {
      return;
    }

    _drawingPointer = null;
    _endStroke();
  }

  void _onCanvasPointerCancel(PointerCancelEvent event) {
    _canvasPointers.remove(event.pointer);
    if (_drawingPointer != event.pointer) {
      return;
    }

    _drawingPointer = null;
    _cancelCanvasInteraction();
  }

  void _beginPan(Offset position, Rect bounds) {
    _lastPanPosition = position;
    if (_freeRotateActive) {
      _beginRotateDrag(position);
      return;
    }
    if (_activeTool.isMoveTool) {
      if (_selection != null && _selection!.contains(position)) {
        _beginMoveSelection(position);
      }
      return;
    }
    if (_activeTool.isSelectionTool) {
      if (_selection?.canReshape == true && _selectionDraft == null) {
        final handle = hitTestSelectionHandle(position, _selection!.bounds);
        if (handle != null) {
          _beginResizeSelection(handle);
          return;
        }
      }

      if (_selection != null && _selection!.contains(position)) {
        _beginMoveSelection(position);
      } else if (_activeTool == PaintTool.lassoSelect) {
        _beginLassoSelection(position, bounds);
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
      case PaintTool.gradient:
        _startGradient(position, bounds);
      case PaintTool.eyedropper:
        _pickColorAt(position, bounds);
      case PaintTool.fillBucket:
        _applyFillAt(position, bounds);
      case PaintTool.magicWand:
        _applyMagicWandSelection(position, bounds);
      case PaintTool.text:
        _beginTextEditing(position, bounds);
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
        isPencil: _isPencil,
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

  void _goToHistoryIndex(int index) {
    setState(() => _layerStack.activeHistory.goToIndex(index));
    _noteDocumentEdited();
  }

  Future<void> _clearCanvas() async {
    if (!_layerStack.hasContent &&
        _currentStroke == null &&
        _textDraft == null) {
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
      _lassoPoints = null;
      _textDraft = null;
      _resetViewport();
    });
    _resetDocumentTracking();
  }

  Future<Uint8List?> _renderCanvasBytes(ImageFileFormat format) async {
    if (_textDraft != null) {
      _commitTextDraft();
    }
    if (_currentStroke != null) {
      setState(_commitCurrentStroke);
    }

    if (_documentSize == Size.zero) {
      return null;
    }

    if (format == ImageFileFormat.ora) {
      return writeOpenRasterBytes(
        size: _documentSize,
        layerStack: _layerStack,
      );
    }

    return renderCanvasToBytes(
      size: _documentSize,
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

  Future<void> _showAiEnhanceError(String message, {String? details}) async {
    if (!mounted) {
      return;
    }

    final fullText = details == null || details.trim().isEmpty
        ? message
        : '$message\n\n$details';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var copied = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('AI Enhance failed'),
              content: SizedBox(
                width: 520,
                child: SelectableText(
                  fullText,
                  style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: fullText));
                    setDialogState(() => copied = true);
                    await Future<void>.delayed(const Duration(seconds: 2));
                    if (context.mounted) {
                      setDialogState(() => copied = false);
                    }
                  },
                  child: Text(copied ? 'Copied' : 'Copy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAiEnhanceSettings() =>
      showAiEnhanceSettingsDialog(context);

  Future<bool> _promptForAiEnhanceSetup() async {
    if (!mounted) {
      return false;
    }

    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Grok not configured'),
          content: const Text(
            'AI Enhance uses Grok. Open Settings to add your API key.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    if (openSettings == true && mounted) {
      await _openAiEnhanceSettings();
      final availability = await checkAiEnhanceAvailability();
      return availability == AiEnhanceAvailability.available;
    }
    return false;
  }

  Future<void> _aiEnhance() async {
    if (_aiEnhanceBusy || _documentSize == Size.zero) {
      return;
    }

    setState(() => _aiEnhanceBusy = true);
    try {
      final availability = await checkAiEnhanceAvailability();
      if (!mounted) {
        return;
      }

      switch (availability) {
        case AiEnhanceAvailability.unsupportedPlatform:
          await _showAiEnhanceError(
            'AI Enhance is not available on this platform.',
          );
          return;
        case AiEnhanceAvailability.notConfigured:
          final configured = await _promptForAiEnhanceSetup();
          if (!configured) {
            return;
          }
          break;
        case AiEnhanceAvailability.unknown:
          await _showAiEnhanceError(
            'Could not check AI Enhance availability.',
          );
          return;
        case AiEnhanceAvailability.available:
          break;
      }

      final source = await captureAiEnhanceSource(
        documentSize: _documentSize,
        strokes: _layerStack.activeHistory.strokes,
        selection: _selection,
      );
      if (!mounted) {
        return;
      }
      if (source == null) {
        await _showAiEnhanceError(
          _selection != null
              ? 'Nothing to enhance in the selection on the active layer.'
              : 'Draw something on the active layer first.',
        );
        return;
      }

      AiEnhanceResult? generated;
      while (true) {
        generated = await showAiEnhanceProgressDialog(
          context: context,
          work: () => enhanceSketch(sourcePng: source.pngBytes),
        );
        if (!mounted) {
          return;
        }
        if (generated == null) {
          await _showAiEnhanceError('AI Enhance was cancelled.');
          return;
        }

        final action = await showAiEnhancePreviewDialog(
          context: context,
          pngBytes: generated.pngBytes,
          width: generated.width,
          height: generated.height,
        );
        if (!mounted) {
          return;
        }

        switch (action) {
          case AiEnhancePreviewAction.apply:
            break;
          case AiEnhancePreviewAction.regenerate:
            continue;
          case AiEnhancePreviewAction.cancel:
            return;
        }
        break;
      }

      final stroke = await strokeFromAiEnhanceResult(
        result: generated,
        placement: source.placement,
      );
      if (!mounted) {
        stroke.rasterImage?.dispose();
        return;
      }

      setState(() {
        _layerStack.activeHistory.add(stroke, label: 'AI Enhance');
        _noteDocumentEdited();
      });
      _showMessage('AI Enhance applied (⌘Z to undo).');
    } on AiEnhanceException catch (error) {
      if (mounted) {
        await _showAiEnhanceError(error.message, details: error.details);
      }
    } catch (error) {
      if (mounted) {
        await _showAiEnhanceError('AI Enhance failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _aiEnhanceBusy = false);
      }
    }
  }

  Future<void> _openCanvas() async {
    try {
      final picked = await pickDocumentFile();
      if (!mounted || picked == null) {
        return;
      }

      setState(() {
        _currentStroke = null;
        _lastPanPosition = null;
        _textDraft = null;
        if (picked.isLayered) {
          _layerStack.loadLayers(picked.layers!);
        } else {
          _layerStack.clear();
          _layerStack.setBackgroundImage(picked.flatImage);
        }
        _documentSize = picked.size;
        _resetViewport();
      });
      _resetDocumentTracking(path: picked.path);
      final openedSize = picked.size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewportSize == Size.zero) {
          return;
        }
        if (openedSize.width > _viewportSize.width ||
            openedSize.height > _viewportSize.height) {
          _setViewport(
            const CanvasViewport().fitToWindow(_viewportSize, openedSize),
          );
        }
      });
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
        isPencil: _isPencil,
      );
    });
  }

  void _startGradient(Offset position, Rect bounds) {
    if (!_isInsideCanvas(position, bounds)) {
      return;
    }

    setState(() {
      _currentStroke = Stroke(
        color: _primaryColor,
        secondaryColor: _gradientEndColor,
        brushSize: 0,
        points: [position, position],
        shape: StrokeShape.gradient,
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
        isPencil: _isPencil,
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
    if (_freeRotateActive) {
      _extendRotateDrag(position);
      return;
    }

    if (_activeTool == PaintTool.eyedropper) {
      _pickColorAt(position, bounds);
      return;
    }

    if (_activeTool == PaintTool.fillBucket ||
        _activeTool == PaintTool.magicWand ||
        _activeTool == PaintTool.text) {
      return;
    }

    if (_activeTool.isMoveTool) {
      if (_movingSelection) {
        _extendMoveSelection(position);
      }
      return;
    }

    if (_activeTool.isSelectionTool) {
      if (_resizingSelection) {
        _extendResizeSelection(position, bounds);
      } else if (_movingSelection) {
        _extendMoveSelection(position);
      } else if (_activeTool == PaintTool.lassoSelect) {
        _extendLassoSelection(position, bounds);
      } else {
        _extendSelectionDrag(position, bounds);
      }
      return;
    }

    switch (_activeTool) {
      case PaintTool.line:
        _extendLine(position, bounds);
        return;
      case PaintTool.gradient:
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
        isPencil: _isPencil,
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
    if (_freeRotateActive) {
      _endRotateDrag();
      return;
    }

    if (_activeTool == PaintTool.eyedropper) {
      _clearEyedropperCache();
      _lastPanPosition = null;
      return;
    }

    if (_activeTool == PaintTool.fillBucket ||
        _activeTool == PaintTool.magicWand ||
        _activeTool == PaintTool.text) {
      _lastPanPosition = null;
      return;
    }

    if (_activeTool.isMoveTool) {
      if (_movingSelection) {
        _endMoveSelection();
      }
      _lastPanPosition = null;
      return;
    }

    if (_activeTool.isSelectionTool) {
      if (_resizingSelection) {
        _endResizeSelection();
      } else if (_movingSelection) {
        _endMoveSelection();
      } else if (_activeTool == PaintTool.lassoSelect) {
        _endLassoSelection();
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
      case PaintTool.gradient:
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

    // While typing text, ignore canvas tools and bare-key app shortcuts so
    // letters reach the TextField. Keep Escape to cancel editing.
    final Map<ShortcutActivator, VoidCallback> bindings = _freeRotateActive
        ? {
            const SingleActivator(LogicalKeyboardKey.escape): _cancelFreeRotate,
          }
        : _textDraft != null
        ? {
            const SingleActivator(LogicalKeyboardKey.escape): _cancelTextDraft,
          }
        : {
            const SingleActivator(LogicalKeyboardKey.bracketLeft): () =>
                _changeBrushSize(-2),
            const SingleActivator(LogicalKeyboardKey.bracketRight): () =>
                _changeBrushSize(2),
            const SingleActivator(LogicalKeyboardKey.keyB): () {
              setState(() => _activeTool = PaintTool.brush);
            },
            const SingleActivator(LogicalKeyboardKey.keyP): () {
              setState(() => _activeTool = PaintTool.pencil);
            },
            const SingleActivator(LogicalKeyboardKey.keyL): () {
              setState(() => _activeTool = PaintTool.line);
            },
            const SingleActivator(LogicalKeyboardKey.keyR): () {
              setState(() => _activeTool = PaintTool.rectangle);
            },
            const SingleActivator(LogicalKeyboardKey.keyO): () {
              setState(() => _activeTool = PaintTool.ellipse);
            },
            const SingleActivator(LogicalKeyboardKey.keyE): () {
              setState(() => _activeTool = PaintTool.eraser);
            },
            const SingleActivator(LogicalKeyboardKey.keyK): () {
              setState(() => _activeTool = PaintTool.eyedropper);
            },
            const SingleActivator(LogicalKeyboardKey.keyG): () {
              setState(() => _activeTool = PaintTool.fillBucket);
            },
            const SingleActivator(
              LogicalKeyboardKey.keyG,
              shift: true,
            ): () {
              setState(() => _activeTool = PaintTool.gradient);
            },
            const SingleActivator(LogicalKeyboardKey.keyT): () {
              _applySelectionTool(PaintTool.text);
            },
            const SingleActivator(LogicalKeyboardKey.keyW): () {
              setState(() => _activeTool = PaintTool.magicWand);
            },
            const SingleActivator(LogicalKeyboardKey.escape): _deselect,
            platformZoomInShortcut: _zoomInFromCenter,
            platformZoomInPlusShortcut: _zoomInFromCenter,
            platformZoomNumpadShortcut(LogicalKeyboardKey.numpadAdd):
                _zoomInFromCenter,
            platformZoomOutShortcut: _zoomOutFromCenter,
            platformZoomNumpadShortcut(LogicalKeyboardKey.numpadSubtract):
                _zoomOutFromCenter,
            platformZoomFitShortcut: _fitCanvasToWindow,
            platformZoomActualSizeShortcut: _zoomToActualSize,
            const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _undo,
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                _undo,
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
            const SingleActivator(LogicalKeyboardKey.keyY, control: true):
                _redo,
            const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
                _saveCanvas(),
            const SingleActivator(LogicalKeyboardKey.keyS, control: true):
                () => _saveCanvas(),
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
            const SingleActivator(LogicalKeyboardKey.keyO, control: true):
                () => _openCanvas(),
            const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
                _clearCanvas(),
            const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                () => _clearCanvas(),
            const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
                _selectAll,
            const SingleActivator(LogicalKeyboardKey.keyA, control: true):
                _selectAll,
            const SingleActivator(
              LogicalKeyboardKey.keyA,
              meta: true,
              shift: true,
            ): _deselect,
            const SingleActivator(
              LogicalKeyboardKey.keyA,
              control: true,
              shift: true,
            ): _deselect,
            const SingleActivator(LogicalKeyboardKey.keyI, meta: true):
                _invertSelection,
            const SingleActivator(LogicalKeyboardKey.keyI, control: true):
                _invertSelection,
            const SingleActivator(LogicalKeyboardKey.delete):
                _eraseSelection,
            const SingleActivator(LogicalKeyboardKey.backspace):
                _eraseSelection,
            SingleActivator(
              LogicalKeyboardKey.keyC,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
            ): () => _copySelection(merged: false),
            SingleActivator(
              LogicalKeyboardKey.keyC,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
              shift: true,
            ): () => _copySelection(merged: true),
            SingleActivator(
              LogicalKeyboardKey.keyX,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
            ): _cutSelection,
            SingleActivator(
              LogicalKeyboardKey.keyV,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
            ): () => _pasteClipboard(
              intoNewLayer: false,
              intoNewImage: false,
            ),
            SingleActivator(
              LogicalKeyboardKey.keyV,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
              shift: true,
            ): () => _pasteClipboard(
              intoNewLayer: true,
              intoNewImage: false,
            ),
            SingleActivator(
              LogicalKeyboardKey.keyV,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
              alt: true,
            ): () => _pasteClipboard(
              intoNewLayer: false,
              intoNewImage: true,
            ),
            SingleActivator(
              LogicalKeyboardKey.keyO,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
              shift: true,
            ): _offsetSelection,
            SingleActivator(
              LogicalKeyboardKey.keyX,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
              shift: true,
            ): () {
              if (_canCropToSelection) {
                _cropToSelection();
              }
            },
            const SingleActivator(
              LogicalKeyboardKey.keyX,
              control: true,
              alt: true,
            ): _autoCrop,
            SingleActivator(
              LogicalKeyboardKey.keyR,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
            ): _resizeImage,
            SingleActivator(
              LogicalKeyboardKey.keyR,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
              shift: true,
            ): _resizeCanvas,
            SingleActivator(
              LogicalKeyboardKey.keyG,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
            ): _rotate90CounterClockwise,
            SingleActivator(
              LogicalKeyboardKey.keyJ,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
            ): _rotate180,
            SingleActivator(
              LogicalKeyboardKey.keyF,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
              shift: true,
            ): _flattenImage,
            const SingleActivator(LogicalKeyboardKey.keyV): () {
              setState(() => _activeTool = PaintTool.moveSelection);
            },
            const SingleActivator(LogicalKeyboardKey.keyF): () {
              setState(() => _activeTool = PaintTool.lassoSelect);
            },
            const SingleActivator(LogicalKeyboardKey.keyS): () {
              setState(() => _activeTool = PaintTool.rectSelect);
            },
          };

    final body = CallbackShortcuts(
      bindings: bindings,
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
                      onSelected: _applySelectionTool,
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
                              onOpenSettings:
                                  !kIsWeb ? _openAiEnhanceSettings : null,
                              onUndo: _undo,
                              onRedo: _redo,
                              canUndo: _layerStack.canUndo,
                              canRedo: _layerStack.canRedo,
                              onCut: _cutSelection,
                              onCopy: () => _copySelection(merged: false),
                              onCopyMerged: () => _copySelection(merged: true),
                              onPaste: () => _pasteClipboard(
                                intoNewLayer: false,
                                intoNewImage: false,
                              ),
                              onPasteIntoNewLayer: () => _pasteClipboard(
                                intoNewLayer: true,
                                intoNewImage: false,
                              ),
                              onPasteIntoNewImage: () => _pasteClipboard(
                                intoNewLayer: false,
                                intoNewImage: true,
                              ),
                              canCutCopy: _canClipboardCopy,
                              canPaste: _canClipboardPaste,
                              onSelectAll: _selectAll,
                              onDeselect: _deselect,
                              canDeselect: _canDeselect,
                              onEraseSelection: _eraseSelection,
                              onFillSelection: _fillSelection,
                              onInvertSelection: _invertSelection,
                              onOffsetSelection: _offsetSelection,
                              onDeleteSelection: _deleteSelection,
                              hasSelection: _hasSelection,
                              onPickPrimaryColor: () => _openColorPicker(
                                ColorWellTarget.primary,
                              ),
                              onPickSecondaryColor: () => _openColorPicker(
                                ColorWellTarget.canvasBackground,
                              ),
                              onSwapColors: _swapColors,
                              onResetColors: _resetColors,
                              onCropToSelection:
                                  _canCropToSelection ? _cropToSelection : null,
                              onAutoCrop: _autoCrop,
                              onResizeImage: _resizeImage,
                              onResizeCanvas: _resizeCanvas,
                              onFlipHorizontal: _flipHorizontal,
                              onFlipVertical: _flipVertical,
                              onRotate90Clockwise: _rotate90Clockwise,
                              onRotate90CounterClockwise:
                                  _rotate90CounterClockwise,
                              onRotate180: _rotate180,
                              onFreeRotate: _beginFreeRotate,
                              onRotate: _showRotateAngleDialog,
                              onFlatten: _flattenImage,
                              onAutoLevel: _autoLevel,
                              onBlackAndWhite: _blackAndWhite,
                              onBrightnessContrast: _brightnessContrast,
                              onCurves: _curves,
                              onHueSaturation: _hueSaturation,
                              onInvertColors: _invertColors,
                              onLevels: _levels,
                              onPosterize: _posterize,
                              onSepia: _sepia,
                              onGlow: _glow,
                              onSharpen: _sharpen,
                              onSoftenPortrait: _softenPortrait,
                              onInkSketch: _inkSketch,
                              onOilPainting: _oilPainting,
                              onPencilSketch: _pencilSketch,
                              onFragment: _fragmentBlur,
                              onGaussianBlur: _gaussianBlur,
                              onMotionBlur: _motionBlur,
                              onRadialBlur: _radialBlur,
                              onUnfocus: _unfocusBlur,
                              onZoomBlur: _zoomBlur,
                              onBulge: _bulge,
                              onFrostedGlass: _frostedGlass,
                              onPixelate: _pixelate,
                              onPolarInversion: _polarInversion,
                              onTileReflection: _tileReflection,
                              onTwist: _twist,
                              onClouds: _clouds,
                              onJuliaFractal: _juliaFractal,
                              onMandelbrotFractal: _mandelbrotFractal,
                              onEdgeDetect: _edgeDetect,
                              onEmboss: _emboss,
                              onOutline: _outline,
                              onRelief: _relief,
                              onDithering: _dithering,
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
                              gradientEndColor: _activeTool == PaintTool.gradient
                                  ? _gradientEndColor
                                  : null,
                              onGradientEndColorTap:
                                  _activeTool == PaintTool.gradient
                                      ? _pickGradientEndColor
                                      : null,
                              textOptions:
                                  _activeTool.isTextTool ? _textOptions : null,
                              onTextOptionsChanged: _activeTool.isTextTool
                                  ? _onTextOptionsChanged
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
                              canReshapeSelection:
                                  _selection?.canReshape ?? false,
                              selectionShape: _selection?.canReshape == true
                                  ? _selection!.shape
                                  : null,
                              onSelectionShapeChanged:
                                  _selection?.canReshape == true
                                      ? _changeSelectionShape
                                      : null,
                              onAiEnhance: !kIsWeb ? _aiEnhance : null,
                              aiEnhanceEnabled: !_aiEnhanceBusy,
                              onOpenSettings:
                                  !kIsWeb ? _openAiEnhanceSettings : null,
                              freeRotateActive: _freeRotateActive,
                              rotateToolbarLabel: _rotateToolbarLabel,
                            ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final viewportSize = Size(
                                          constraints.maxWidth,
                                          constraints.maxHeight,
                                        );
                                        _syncViewportSize(viewportSize);
                                        if (_documentSize == Size.zero &&
                                            viewportSize != Size.zero) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (mounted &&
                                                _documentSize == Size.zero) {
                                              setState(
                                                () => _documentSize =
                                                    viewportSize,
                                              );
                                            }
                                          });
                                          return const SizedBox.expand();
                                        }

                                        final canvasSize = _documentSize;
                                        final bounds = Offset.zero & canvasSize;

                                        return ClipRect(
                                          child: Stack(
                                            clipBehavior: Clip.hardEdge,
                                            children: [
                                              Positioned.fill(
                                                child: MouseRegion(
                                            cursor: _canvasCursor,
                                            onHover: (event) =>
                                                _updateCanvasCursor(
                                              _viewport.viewportToDocument(
                                                event.localPosition,
                                              ),
                                            ),
                                            onExit: (_) => _resetCanvasCursor(),
                                            child: Listener(
                                              behavior: HitTestBehavior.opaque,
                                              onPointerSignal:
                                                  _onViewportPointerSignal,
                                              onPointerPanZoomStart:
                                                  _onViewportPointerPanZoomStart,
                                              onPointerPanZoomUpdate:
                                                  _onViewportPointerPanZoomUpdate,
                                              onPointerPanZoomEnd:
                                                  _onViewportPointerPanZoomEnd,
                                              onPointerDown: (event) =>
                                                  _onViewportPointerDown(
                                                event,
                                                bounds,
                                              ),
                                              onPointerMove: (event) =>
                                                  _onViewportPointerMove(
                                                event,
                                                bounds,
                                              ),
                                              onPointerUp: _onViewportPointerUp,
                                              onPointerCancel:
                                                  _onViewportPointerCancel,
                                              child: ColoredBox(
                                                color: AppColors.workspace,
                                                child: Transform(
                                                  transform: Matrix4.identity()
                                                    ..translateByDouble(
                                                      _viewport.pan.dx,
                                                      _viewport.pan.dy,
                                                      0,
                                                      1,
                                                    )
                                                    ..scaleByDouble(
                                                      _viewport.scale,
                                                      _viewport.scale,
                                                      1,
                                                      1,
                                                    ),
                                                  child: SizedBox(
                                                    width: canvasSize.width,
                                                    height: canvasSize.height,
                                                    child: AnimatedBuilder(
                                                      animation:
                                                          _marchingAntsController,
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
                                                                showHandles:
                                                                    _selection?.canReshape ==
                                                                            true &&
                                                                        _selectionDraft ==
                                                                            null &&
                                                                        _activeTool
                                                                            .isSelectionTool,
                                                              ),
                                                            ),
                                                            if (_rotatePreviewActive)
                                                              CustomPaint(
                                                                painter:
                                                                    RotateOverlayPainter(
                                                                  center:
                                                                      _canvasCenter,
                                                                  dragPosition:
                                                                      _rotateOverlayDragPosition,
                                                                  startAngle:
                                                                      _freeRotateActive
                                                                          ? _rotateStartAngle
                                                                          : 0,
                                                                  previewAngle:
                                                                      _rotatePreviewAngle,
                                                                ),
                                                              ),
                                                          ],
                                                        );
                                                      },
                                                      child: CustomPaint(
                                                        painter: CanvasPainter(
                                                          layers: _layerStack
                                                              .layers,
                                                          activeLayerIndex:
                                                              _layerStack
                                                                  .activeIndex,
                                                          currentStroke:
                                                              _currentStroke,
                                                          backgroundImage:
                                                              _layerStack
                                                                  .backgroundImage,
                                                          backgroundColor:
                                                              _layerStack
                                                                  .backgroundColor,
                                                          previewRotation:
                                                              _rotatePreviewAngle,
                                                        ),
                                                        child: const SizedBox
                                                            .expand(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                              ),
                                              if (_textDraft != null)
                                                CanvasTextEditor(
                                                  draft: _textDraft!,
                                                  viewportPosition: _viewport
                                                      .documentToViewport(
                                                    _textDraft!.position,
                                                  ),
                                                  scale: _viewport.scale,
                                                  onChanged: _updateTextDraft,
                                                  onCommit: _commitTextDraft,
                                                  onCancel: _cancelTextDraft,
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: LayersPanel.width,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: LayersPanel(
                                            layers: _layerStack.layers,
                                            activeIndex: _layerStack.activeIndex,
                                            canDeleteLayer:
                                                _layerStack.canDeleteLayer,
                                            canMoveLayerUp:
                                                _layerStack.canMoveLayerUp,
                                            canMoveLayerDown:
                                                _layerStack.canMoveLayerDown,
                                            canMergeDown:
                                                _layerStack.canMergeDown,
                                            onLayerSelected: (index) {
                                              setState(
                                                () => _layerStack
                                                    .setActiveLayer(index),
                                              );
                                            },
                                            onToggleVisibility: (index) {
                                              setState(
                                                () => _layerStack
                                                    .toggleVisibility(index),
                                              );
                                              _noteDocumentEdited();
                                            },
                                            onAddLayer: () {
                                              setState(_layerStack.addLayer);
                                              _noteDocumentEdited();
                                            },
                                            onDuplicateLayer: (index) {
                                              setState(
                                                () => _layerStack
                                                    .duplicateLayer(index),
                                              );
                                              _noteDocumentEdited();
                                            },
                                            onDeleteLayer: _deleteLayer,
                                            onMoveLayerUp: (index) {
                                              setState(
                                                () => _layerStack
                                                    .moveLayerUp(index),
                                              );
                                              _noteDocumentEdited();
                                            },
                                            onMoveLayerDown: (index) {
                                              setState(
                                                () => _layerStack
                                                    .moveLayerDown(index),
                                              );
                                              _noteDocumentEdited();
                                            },
                                            onMergeDown: _mergeDownLayer,
                                            onRenameLayer: (index, name) {
                                              setState(
                                                () => _layerStack.renameLayer(
                                                  index,
                                                  name,
                                                ),
                                              );
                                              _noteDocumentEdited();
                                            },
                                            onOpacityChanged: (opacity) {
                                              setState(
                                                () => _layerStack
                                                    .setLayerOpacity(
                                                  _layerStack.activeIndex,
                                                  opacity,
                                                ),
                                              );
                                              _noteDocumentEdited();
                                            },
                                            onBlendModeChanged: (mode) {
                                              setState(
                                                () => _layerStack
                                                    .setLayerBlendMode(
                                                  _layerStack.activeIndex,
                                                  mode,
                                                ),
                                              );
                                              _noteDocumentEdited();
                                            },
                                          ),
                                        ),
                                        HistoryPanel(
                                          layerName: _layerStack.activeLayer.name,
                                          actions: _layerStack
                                              .activeHistory.timeline,
                                          currentIndex: _layerStack
                                              .activeHistory.currentIndex,
                                          onGoToIndex: _goToHistoryIndex,
                                        ),
                                      ],
                                    ),
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
                                  primaryColor: _primaryColor,
                                  primaryPresetIndex: _primaryPresetIndex,
                                  canvasBackgroundColor:
                                      _layerStack.backgroundColor,
                                  colorTarget: _colorTarget,
                                  onColorTargetChanged: (target) {
                                    setState(() => _colorTarget = target);
                                  },
                                  onPrimarySelected: (index) {
                                    setState(
                                      () => _primaryColor =
                                          AppColors.presetColors[index],
                                    );
                                    if (_textDraft != null) {
                                      _syncTextDraftStyleFromToolbar();
                                    }
                                  },
                                  onCanvasBackgroundChanged: (color) {
                                    setState(
                                      () => _layerStack.setBackgroundColor(color),
                                    );
                                    _noteDocumentEdited();
                                  },
                                  onSwapColors: _swapColors,
                                  onResetColors: _resetColors,
                                  onPrimaryDoubleTap: () => _openColorPicker(
                                    ColorWellTarget.primary,
                                  ),
                                  onSecondaryDoubleTap: () => _openColorPicker(
                                    ColorWellTarget.canvasBackground,
                                  ),
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
                  '${_activeTool.label} ${_brushSize.round()}px  |  ${_viewport.zoomPercentLabel}%  |  $_colorStatusLabel  |  ${_layerStack.activeLayer.name}  |  $_statusHint  |  $_viewportHint',
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
          onOpenSettings: !kIsWeb ? _openAiEnhanceSettings : null,
          onUndo: _undo,
          onRedo: _redo,
          canUndo: _layerStack.canUndo,
          canRedo: _layerStack.canRedo,
          onCut: _cutSelection,
          onCopy: () => _copySelection(merged: false),
          onCopyMerged: () => _copySelection(merged: true),
          onPaste: () => _pasteClipboard(
            intoNewLayer: false,
            intoNewImage: false,
          ),
          onPasteIntoNewLayer: () => _pasteClipboard(
            intoNewLayer: true,
            intoNewImage: false,
          ),
          onPasteIntoNewImage: () => _pasteClipboard(
            intoNewLayer: false,
            intoNewImage: true,
          ),
          canCutCopy: _canClipboardCopy,
          canPaste: _canClipboardPaste,
          onSelectAll: _selectAll,
          onDeselect: _deselect,
          canDeselect: _canDeselect,
          onEraseSelection: _eraseSelection,
          onFillSelection: _fillSelection,
          onInvertSelection: _invertSelection,
          onOffsetSelection: _offsetSelection,
          onDeleteSelection: _deleteSelection,
          hasSelection: _hasSelection,
          onPickPrimaryColor: () => _openColorPicker(
            ColorWellTarget.primary,
          ),
          onPickSecondaryColor: () => _openColorPicker(
            ColorWellTarget.canvasBackground,
          ),
          onSwapColors: _swapColors,
          onResetColors: _resetColors,
          onCropToSelection:
              _canCropToSelection ? _cropToSelection : null,
          onAutoCrop: _autoCrop,
          onResizeImage: _resizeImage,
          onResizeCanvas: _resizeCanvas,
          onFlipHorizontal: _flipHorizontal,
          onFlipVertical: _flipVertical,
          onRotate90Clockwise: _rotate90Clockwise,
          onRotate90CounterClockwise: _rotate90CounterClockwise,
          onRotate180: _rotate180,
          onFreeRotate: _beginFreeRotate,
          onRotate: _showRotateAngleDialog,
          onFlatten: _flattenImage,
          onAutoLevel: _autoLevel,
          onBlackAndWhite: _blackAndWhite,
          onBrightnessContrast: _brightnessContrast,
          onCurves: _curves,
          onHueSaturation: _hueSaturation,
          onInvertColors: _invertColors,
          onLevels: _levels,
          onPosterize: _posterize,
          onSepia: _sepia,
          onGlow: _glow,
          onSharpen: _sharpen,
          onSoftenPortrait: _softenPortrait,
          onInkSketch: _inkSketch,
          onOilPainting: _oilPainting,
          onPencilSketch: _pencilSketch,
          onFragment: _fragmentBlur,
          onGaussianBlur: _gaussianBlur,
          onMotionBlur: _motionBlur,
          onRadialBlur: _radialBlur,
          onUnfocus: _unfocusBlur,
          onZoomBlur: _zoomBlur,
          onBulge: _bulge,
          onFrostedGlass: _frostedGlass,
          onPixelate: _pixelate,
          onPolarInversion: _polarInversion,
          onTileReflection: _tileReflection,
          onTwist: _twist,
          onClouds: _clouds,
          onJuliaFractal: _juliaFractal,
          onMandelbrotFractal: _mandelbrotFractal,
          onEdgeDetect: _edgeDetect,
          onEmboss: _emboss,
          onOutline: _outline,
          onRelief: _relief,
          onDithering: _dithering,
        ),
        child: body,
      );
    }

    return body;
  }
}
