import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/theme/app_colors.dart';

class BrushSizeControl extends StatefulWidget {
  const BrushSizeControl({
    super.key,
    required this.brushSize,
    required this.onChanged,
  });

  static const double minSize = 2;
  static const double maxSize = 48;

  final double brushSize;
  final ValueChanged<double> onChanged;

  @override
  State<BrushSizeControl> createState() => _BrushSizeControlState();
}

class _BrushSizeControlState extends State<BrushSizeControl> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.brushSize.round().toString(),
    );
  }

  @override
  void didUpdateWidget(BrushSizeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.brushSize.round().toString();
    if (text != _controller.text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setSize(double size) {
    final clamped = size.clamp(BrushSizeControl.minSize, BrushSizeControl.maxSize);
    widget.onChanged(clamped);
    _controller.text = clamped.round().toString();
  }

  void _step(int delta) {
    _setSize(widget.brushSize + delta);
  }

  void _applyInput() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = widget.brushSize.round().toString();
      return;
    }
    _setSize(parsed.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    const fieldStyle = TextStyle(
      color: AppColors.statusText,
      fontSize: 14,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Brush width',
          style: TextStyle(
            color: AppColors.paletteLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        _StepButton(
          label: '−',
          onPressed: () => _step(-1),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 48,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: fieldStyle,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              ),
              filled: true,
              fillColor: AppColors.workspace,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.paletteBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.paletteBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.statusText),
              ),
            ),
            onSubmitted: (_) => _applyInput(),
            onEditingComplete: _applyInput,
            onTapOutside: (_) => _applyInput(),
          ),
        ),
        const SizedBox(width: 4),
        _StepButton(
          label: '+',
          onPressed: () => _step(1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.statusText,
          side: const BorderSide(color: AppColors.paletteBorder),
          backgroundColor: AppColors.workspace,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, height: 1),
        ),
      ),
    );
  }
}
