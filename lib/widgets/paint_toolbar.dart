import 'package:flutter/material.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';
import 'package:vibepaint/widgets/shape_style_control.dart';

class PaintToolbar extends StatelessWidget {
  const PaintToolbar({
    super.key,
    required this.brushSize,
    required this.onBrushSizeChanged,
    this.shapeStyle,
    this.onShapeStyleChanged,
    required this.canUndo,
    required this.canRedo,
    required this.canSave,
    required this.canClear,
    required this.onUndo,
    required this.onRedo,
    required this.onOpen,
    required this.onSave,
    required this.onClear,
  });

  final double brushSize;
  final ValueChanged<double> onBrushSizeChanged;
  final ShapeStyle? shapeStyle;
  final ValueChanged<ShapeStyle>? onShapeStyleChanged;
  final bool canUndo;
  final bool canRedo;
  final bool canSave;
  final bool canClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.palettePanel,
        border: Border(
          bottom: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: Row(
        children: [
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
          const Spacer(),
          _ToolbarIconButton(
            icon: Icons.folder_open_outlined,
            tooltip: 'Open PNG',
            enabled: true,
            onPressed: onOpen,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            icon: Icons.save_outlined,
            tooltip: 'Save PNG',
            enabled: canSave,
            onPressed: onSave,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            icon: Icons.note_add_outlined,
            tooltip: 'Clear canvas',
            enabled: canClear,
            onPressed: onClear,
          ),
          const SizedBox(width: 4),
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
