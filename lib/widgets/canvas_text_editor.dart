import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/models/text_run.dart';
import 'package:vibepaint/theme/app_colors.dart';

class CanvasTextEditor extends StatefulWidget {
  const CanvasTextEditor({
    super.key,
    required this.draft,
    required this.viewportPosition,
    required this.scale,
    required this.onChanged,
    required this.onCommit,
    required this.onCancel,
  });

  final TextRun draft;
  final Offset viewportPosition;
  final double scale;
  final ValueChanged<TextRun> onChanged;
  final VoidCallback onCommit;
  final VoidCallback onCancel;

  @override
  State<CanvasTextEditor> createState() => _CanvasTextEditorState();
}

class _CanvasTextEditorState extends State<CanvasTextEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.draft.text);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CanvasTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.text != widget.draft.text &&
        _controller.text != widget.draft.text) {
      _controller.value = TextEditingValue(
        text: widget.draft.text,
        selection: TextSelection.collapsed(offset: widget.draft.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onCancel();
      return KeyEventResult.handled;
    }

    final enter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (enter && !shift) {
      widget.onCommit();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.draft.textStyle;
    final scaledStyle = style.copyWith(
      fontSize: (style.fontSize ?? 16) * widget.scale,
      height: style.height,
    );
    final minWidth = 24.0 * widget.scale;
    final minHeight = ((style.fontSize ?? 16) * 1.2 + 8) * widget.scale;

    return Positioned(
      left: widget.viewportPosition.dx,
      top: widget.viewportPosition.dy,
      child: Focus(
        onKeyEvent: _onKey,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minHeight,
            maxWidth: 480 * widget.scale,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.statusText, width: 1),
            ),
            child: IntrinsicWidth(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: scaledStyle,
                cursorColor: widget.draft.color,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                ),
                onChanged: (value) {
                  widget.onChanged(widget.draft.copyWith(text: value));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
