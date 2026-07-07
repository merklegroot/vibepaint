import 'package:flutter/material.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/widgets/brush_size_control.dart';
import 'package:vibepaint/widgets/tool_selector.dart';

class PaintToolbar extends StatelessWidget {
  const PaintToolbar({
    super.key,
    required this.activeTool,
    required this.onToolChanged,
    required this.brushSize,
    required this.onBrushSizeChanged,
  });

  final PaintTool activeTool;
  final ValueChanged<PaintTool> onToolChanged;
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
          ToolSelector(
            selected: activeTool,
            onSelected: onToolChanged,
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 32,
            color: AppColors.paletteBorder,
          ),
          const SizedBox(width: 16),
          BrushSizeControl(
            brushSize: brushSize,
            onChanged: onBrushSizeChanged,
          ),
        ],
      ),
    );
  }
}
