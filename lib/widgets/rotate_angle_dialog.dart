import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/theme/app_colors.dart';

class RotateAngleDialog extends StatefulWidget {
  const RotateAngleDialog({
    super.key,
    this.initialDegrees = 0,
    required this.onAngleChanged,
  });

  final double initialDegrees;
  final ValueChanged<double> onAngleChanged;

  @override
  State<RotateAngleDialog> createState() => _RotateAngleDialogState();
}

class _RotateAngleDialogState extends State<RotateAngleDialog> {
  late final TextEditingController _controller;
  late double _degrees;

  @override
  void initState() {
    super.initState();
    _degrees = widget.initialDegrees;
    _controller = TextEditingController(text: _formatDegrees(_degrees));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAngleChanged(_degrees);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDegrees(double degrees) {
    if (degrees == degrees.roundToDouble()) {
      return degrees.round().toString();
    }
    return degrees.toStringAsFixed(1);
  }

  void _setDegrees(double degrees) {
    setState(() {
      _degrees = degrees;
      _controller.text = _formatDegrees(degrees);
    });
    widget.onAngleChanged(degrees);
  }

  void _step(double delta) {
    _setDegrees(_degrees + delta);
  }

  void _applyInput() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = _formatDegrees(_degrees);
      return;
    }
    _setDegrees(parsed);
  }

  void _submit() {
    _applyInput();
    Navigator.of(context).pop(_degrees);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'Rotate',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Angle (degrees)',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepButton(
                  label: '−',
                  onPressed: () => _step(-1),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.statusText,
                      fontSize: 14,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d*'),
                      ),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: AppColors.workspace,
                      suffixText: '°',
                      suffixStyle: const TextStyle(
                        color: AppColors.paletteLabel,
                      ),
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.paletteBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.paletteBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.statusText),
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value.trim());
                      if (parsed != null) {
                        setState(() => _degrees = parsed);
                        widget.onAngleChanged(parsed);
                      }
                    },
                    onSubmitted: (_) => _applyInput(),
                    onEditingComplete: _applyInput,
                    onTapOutside: (_) => _applyInput(),
                  ),
                ),
                const SizedBox(width: 8),
                _StepButton(
                  label: '+',
                  onPressed: () => _step(1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Positive rotates clockwise. Preview updates on the canvas.',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('OK'),
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
      width: 36,
      height: 36,
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
          style: const TextStyle(fontSize: 20, height: 1),
        ),
      ),
    );
  }
}
