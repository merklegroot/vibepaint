import 'package:flutter/material.dart';
import 'package:vibepaint/models/paint_tool.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/platform_features.dart';
import 'package:vibepaint/widgets/tool_svg_icon.dart';

class ToolToolbar extends StatelessWidget {
  const ToolToolbar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.tools,
    this.horizontal = false,
  });

  static const double width = 52;

  final PaintTool selected;
  final ValueChanged<PaintTool> onSelected;
  final List<PaintTool>? tools;
  final bool horizontal;

  List<PaintTool> get _tools => tools ?? availablePaintTools;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Container(
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.palettePanel,
          border: Border(
            bottom: BorderSide(color: AppColors.paletteBorder),
          ),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: _tools.length,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final tool = _tools[index];
            return _ToolButton(
              tool: tool,
              selected: selected == tool,
              onPressed: () => onSelected(tool),
            );
          },
        ),
      );
    }

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.palettePanel,
        border: Border(
          right: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 8),
          for (final tool in _tools) ...[
            if (tool == PaintTool.rectSelect)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Divider(height: 1, color: AppColors.paletteBorder),
              ),
            _ToolButton(
              tool: tool,
              selected: selected == tool,
              onPressed: () => onSelected(tool),
            ),
          ],
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
