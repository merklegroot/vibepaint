import 'package:flutter/material.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/widgets/tool_svg_icon.dart';

class ToolToolbar extends StatelessWidget {
  const ToolToolbar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const double width = 52;

  final PaintTool selected;
  final ValueChanged<PaintTool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.palettePanel,
        border: Border(
          right: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  for (final tool in PaintTool.values) ...[
                    if (tool == PaintTool.moveSelection)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Divider(
                          height: 1,
                          color: AppColors.paletteBorder,
                        ),
                      ),
                    _ToolButton(
                      tool: tool,
                      selected: selected == tool,
                      onPressed: () => onSelected(tool),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tool,
    required this.selected,
    required this.onPressed,
  });

  final PaintTool tool;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Tooltip(
        message: tool.label,
        child: Material(
          color: selected ? AppColors.workspace : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? AppColors.statusText
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: ToolSvgIcon(
                  tool: tool,
                  color: AppColors.statusText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
