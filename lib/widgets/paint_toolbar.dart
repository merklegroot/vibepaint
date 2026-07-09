import 'package:flutter/material.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';
import 'package:vibepaint/widgets/selection_shape_control.dart';
import 'package:vibepaint/widgets/shape_style_control.dart';
import 'package:vibepaint/widgets/text_tool_options_control.dart';

class PaintToolbar extends StatelessWidget {
  const PaintToolbar({
    super.key,
    required this.brushSize,
    required this.onBrushSizeChanged,
    this.shapeStyle,
    this.onShapeStyleChanged,
    this.gradientEndColor,
    this.onGradientEndColorTap,
    this.textOptions,
    this.onTextOptionsChanged,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.hasSelection,
    required this.onSelectAll,
    required this.onDeselect,
    required this.onInvertSelection,
    required this.onDeleteSelection,
    this.canReshapeSelection = false,
    this.selectionShape,
    this.onSelectionShapeChanged,
    this.onAiEnhance,
    this.aiEnhanceEnabled = true,
    this.onOpenSettings,
    this.freeRotateActive = false,
    this.rotateToolbarLabel,
  });

  final double brushSize;
  final ValueChanged<double> onBrushSizeChanged;
  final ShapeStyle? shapeStyle;
  final ValueChanged<ShapeStyle>? onShapeStyleChanged;
  final Color? gradientEndColor;
  final VoidCallback? onGradientEndColorTap;
  final TextToolOptions? textOptions;
  final ValueChanged<TextToolOptions>? onTextOptionsChanged;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool hasSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselect;
  final VoidCallback onInvertSelection;
  final VoidCallback onDeleteSelection;
  final bool canReshapeSelection;
  final SelectionShape? selectionShape;
  final ValueChanged<SelectionShape>? onSelectionShapeChanged;
  final VoidCallback? onAiEnhance;
  final bool aiEnhanceEnabled;
  final VoidCallback? onOpenSettings;
  final bool freeRotateActive;
  final String? rotateToolbarLabel;

  @override
  Widget build(BuildContext context) {
    final rotateActive = rotateToolbarLabel != null;
    final showBrushSize = textOptions == null &&
        gradientEndColor == null &&
        !freeRotateActive &&
        !rotateActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.palettePanel,
        border: Border(
          bottom: BorderSide(
            color: rotateActive
                ? AppColors.statusText.withValues(alpha: 0.45)
                : AppColors.paletteBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          if (rotateToolbarLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.workspace,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.statusText),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    freeRotateActive ? Icons.rotate_right : Icons.rotate_90_degrees_cw,
                    size: 16,
                    color: AppColors.statusText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rotateToolbarLabel!,
                    style: const TextStyle(
                      color: AppColors.statusText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (showBrushSize)
            BrushSizeControl(
              brushSize: brushSize,
              onChanged: onBrushSizeChanged,
            ),
          if (shapeStyle != null && onShapeStyleChanged != null) ...[
            const SizedBox(width: 16),
            ShapeStyleControl(
              style: shapeStyle!,
              onChanged: onShapeStyleChanged!,
            ),
          ],
          if (gradientEndColor != null && onGradientEndColorTap != null) ...[
            const SizedBox(width: 16),
            _GradientEndColorControl(
              color: gradientEndColor!,
              onTap: onGradientEndColorTap!,
            ),
          ],
          if (textOptions != null && onTextOptionsChanged != null) ...[
            if (showBrushSize) const SizedBox(width: 16),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: TextToolOptionsControl(
                  options: textOptions!,
                  onChanged: onTextOptionsChanged!,
                ),
              ),
            ),
          ],
          const SizedBox(width: 16),
          _ToolbarIconButton(
            icon: Icons.select_all,
            tooltip: 'Select all',
            enabled: true,
            onPressed: onSelectAll,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            icon: Icons.highlight_off,
            tooltip: 'Deselect',
            enabled: hasSelection,
            onPressed: onDeselect,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            icon: Icons.flip,
            tooltip: 'Invert selection',
            enabled: hasSelection,
            onPressed: onInvertSelection,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete selection',
            enabled: hasSelection,
            onPressed: onDeleteSelection,
          ),
          if (canReshapeSelection &&
              selectionShape != null &&
              onSelectionShapeChanged != null) ...[
            const SizedBox(width: 16),
            SelectionShapeControl(
              shape: selectionShape!,
              onChanged: onSelectionShapeChanged!,
            ),
          ],
          if (onAiEnhance != null) ...[
            const SizedBox(width: 16),
            _ToolbarIconButton(
              icon: Icons.auto_awesome,
              tooltip: 'AI Enhance',
              enabled: aiEnhanceEnabled,
              onPressed: onAiEnhance!,
            ),
          ],
          if (onOpenSettings != null) ...[
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.settings,
              tooltip: 'AI Enhance Settings',
              enabled: true,
              onPressed: onOpenSettings!,
            ),
          ],
          const Spacer(),
          _ToolbarIconButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            enabled: canUndo,
            onPressed: onUndo,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            enabled: canRedo,
            onPressed: onRedo,
          ),
        ],
      ),
    );
  }
}

class _GradientEndColorControl extends StatelessWidget {
  const _GradientEndColorControl({
    required this.color,
    required this.onTap,
  });

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Gradient end color',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'End',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: AppColors.paletteBorder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        color: AppColors.statusText,
        disabledColor: AppColors.paletteBorder,
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.workspace,
        ),
      ),
    );
  }
}
