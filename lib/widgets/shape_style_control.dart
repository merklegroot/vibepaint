import 'package:flutter/material.dart';
import 'package:vibepaint/models/shape_style.dart';
import 'package:vibepaint/theme/app_colors.dart';

class ShapeStyleControl extends StatelessWidget {
  const ShapeStyleControl({
    super.key,
    required this.style,
    required this.onChanged,
  });

  final ShapeStyle style;
  final ValueChanged<ShapeStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Shape',
          style: TextStyle(
            color: AppColors.paletteLabel,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        for (final option in ShapeStyle.values) ...[
          if (option != ShapeStyle.values.first) const SizedBox(width: 4),
          _ShapeStyleButton(
            style: option,
            selected: style == option,
            onPressed: () => onChanged(option),
          ),
        ],
      ],
    );
  }
}

class _ShapeStyleButton extends StatelessWidget {
  const _ShapeStyleButton({
    required this.style,
    required this.selected,
    required this.onPressed,
  });

  final ShapeStyle style;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: style.label,
      child: Material(
        color: selected ? AppColors.workspace : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected
                    ? AppColors.statusText
                    : AppColors.paletteBorder,
              ),
            ),
            child: CustomPaint(
              painter: _ShapeStyleIconPainter(style),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeStyleIconPainter extends CustomPainter {
  const _ShapeStyleIconPainter(this.style);

  final ShapeStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.25,
      size.width * 0.6,
      size.height * 0.5,
    );
    final fill = Paint()
      ..color = AppColors.statusText
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = AppColors.statusText
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (style.drawsFill) {
      canvas.drawRect(rect, fill);
    }
    if (style.drawsOutline) {
      canvas.drawRect(rect, outline);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeStyleIconPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}
