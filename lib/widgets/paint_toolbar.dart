import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';

class PaintToolbar extends StatelessWidget {
  const PaintToolbar({
    super.key,
    required this.brushSize,
    required this.onBrushSizeChanged,
  });

  final double brushSize;
  final ValueChanged<double> onBrushSizeChanged;

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
        ],
      ),
    );
  }
}
