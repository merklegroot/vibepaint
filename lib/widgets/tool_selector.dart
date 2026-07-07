import 'package:flutter/material.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/theme/app_colors.dart';

class ToolSelector extends StatelessWidget {
  const ToolSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PaintTool selected;
  final ValueChanged<PaintTool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tool in PaintTool.values) ...[
          if (tool != PaintTool.values.first) const SizedBox(width: 4),
          _ToolButton(
            label: tool.label,
            selected: selected == tool,
            onPressed: () => onSelected(tool),
          ),
        ],
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        foregroundColor: AppColors.statusText,
        backgroundColor:
            selected ? AppColors.workspace : AppColors.palettePanel,
        side: BorderSide(
          color: selected ? AppColors.statusText : AppColors.paletteBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
