import 'package:flutter/material.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/widgets/tool_svg_icon.dart';

class SelectionShapeControl extends StatelessWidget {
  const SelectionShapeControl({
    super.key,
    required this.shape,
    required this.onChanged,
  });

  final SelectionShape shape;
  final ValueChanged<SelectionShape> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShapeButton(
          icon: const ToolSvgIcon(
            tool: PaintTool.rectSelect,
            size: 18,
            color: AppColors.statusText,
          ),
          tooltip: 'Rectangle selection',
          selected: shape == SelectionShape.rectangle,
          onPressed: () => onChanged(SelectionShape.rectangle),
        ),
        const SizedBox(width: 4),
        _ShapeButton(
          icon: const ToolSvgIcon(
            tool: PaintTool.ellipseSelect,
            size: 18,
            color: AppColors.statusText,
          ),
          tooltip: 'Ellipse selection',
          selected: shape == SelectionShape.ellipse,
          onPressed: () => onChanged(SelectionShape.ellipse),
        ),
      ],
    );
  }
}

class _ShapeButton extends StatelessWidget {
  const _ShapeButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: AppColors.statusText,
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          backgroundColor:
              selected ? AppColors.workspace : Colors.transparent,
          side: selected
              ? const BorderSide(color: AppColors.statusText)
              : BorderSide.none,
        ),
      ),
    );
  }
}
