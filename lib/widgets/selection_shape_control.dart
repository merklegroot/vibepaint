import 'package:flutter/material.dart';
import 'package:vibepaint/models/canvas_selection.dart';
import 'package:vibepaint/theme/app_colors.dart';

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
          icon: Icons.crop_free,
          tooltip: 'Rectangle selection',
          selected: shape == SelectionShape.rectangle,
          onPressed: () => onChanged(SelectionShape.rectangle),
        ),
        const SizedBox(width: 4),
        _ShapeButton(
          icon: Icons.radio_button_unchecked,
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

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
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
