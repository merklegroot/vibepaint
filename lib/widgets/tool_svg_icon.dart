import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vibepaint/models/paint_tool.dart';

class ToolSvgIcon extends StatelessWidget {
  const ToolSvgIcon({
    super.key,
    required this.tool,
    required this.color,
    this.size = 20,
  });

  final PaintTool tool;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      tool.iconAsset,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
    );
  }
}

extension PaintToolIconAsset on PaintTool {
  String get iconAsset => switch (this) {
        PaintTool.brush => 'assets/icons/tools/brush.svg',
        PaintTool.pencil => 'assets/icons/tools/pencil.svg',
        PaintTool.line => 'assets/icons/tools/line.svg',
        PaintTool.rectangle => 'assets/icons/tools/rectangle.svg',
        PaintTool.ellipse => 'assets/icons/tools/ellipse.svg',
        PaintTool.eraser => 'assets/icons/tools/eraser.svg',
        PaintTool.eyedropper => 'assets/icons/tools/eyedropper.svg',
        PaintTool.rectSelect => 'assets/icons/tools/rect_select.svg',
        PaintTool.ellipseSelect => 'assets/icons/tools/ellipse_select.svg',
        PaintTool.lassoSelect => 'assets/icons/tools/lasso.svg',
      };
}
