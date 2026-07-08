import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';

class TextStyleControl extends StatelessWidget {
  const TextStyleControl({
    super.key,
    required this.bold,
    required this.italic,
    required this.onBoldChanged,
    required this.onItalicChanged,
  });

  final bool bold;
  final bool italic;
  final ValueChanged<bool> onBoldChanged;
  final ValueChanged<bool> onItalicChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StyleToggle(
          label: 'B',
          tooltip: 'Bold',
          selected: bold,
          onPressed: () => onBoldChanged(!bold),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        _StyleToggle(
          label: 'I',
          tooltip: 'Italic',
          selected: italic,
          onPressed: () => onItalicChanged(!italic),
          textStyle: const TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _StyleToggle extends StatelessWidget {
  const _StyleToggle({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    required this.textStyle,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? AppColors.workspace : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected ? AppColors.statusText : AppColors.paletteBorder,
              ),
            ),
            child: Text(
              label,
              style: textStyle.copyWith(
                color: AppColors.statusText,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
