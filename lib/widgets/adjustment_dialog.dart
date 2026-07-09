import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/theme/app_colors.dart';

class AdjustmentSliderSpec {
  const AdjustmentSliderSpec({
    required this.label,
    required this.min,
    required this.max,
    required this.initial,
    this.divisions,
    this.suffix,
  });

  final String label;
  final double min;
  final double max;
  final double initial;
  final int? divisions;
  final String? suffix;
}

class AdjustmentDialog extends StatefulWidget {
  const AdjustmentDialog({
    super.key,
    required this.title,
    required this.sliders,
    required this.onValuesChanged,
    this.footer,
  });

  final String title;
  final List<AdjustmentSliderSpec> sliders;
  final ValueChanged<List<double>> onValuesChanged;
  final String? footer;

  @override
  State<AdjustmentDialog> createState() => _AdjustmentDialogState();
}

class _AdjustmentDialogState extends State<AdjustmentDialog> {
  late final List<TextEditingController> _controllers;
  late List<double> _values;

  @override
  void initState() {
    super.initState();
    _values = [for (final slider in widget.sliders) slider.initial];
    _controllers = [
      for (final value in _values)
        TextEditingController(text: _formatValue(value)),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValuesChanged(_values);
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  void _setValue(int index, double value) {
    final spec = widget.sliders[index];
    final clamped = value.clamp(spec.min, spec.max);
    setState(() {
      _values[index] = clamped;
      _controllers[index].text = _formatValue(clamped);
    });
    widget.onValuesChanged(_values);
  }

  void _step(int index, double delta) {
    _setValue(index, _values[index] + delta);
  }

  void _applyInput(int index) {
    final parsed = double.tryParse(_controllers[index].text.trim());
    if (parsed == null) {
      _controllers[index].text = _formatValue(_values[index]);
      return;
    }
    _setValue(index, parsed);
  }

  void _submit() {
    for (var i = 0; i < widget.sliders.length; i++) {
      _applyInput(i);
    }
    Navigator.of(context).pop(_values);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: Text(
        widget.title,
        style: const TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.sliders.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _SliderRow(
                spec: widget.sliders[i],
                controller: _controllers[i],
                value: _values[i],
                onDecrement: () => _step(i, -1),
                onIncrement: () => _step(i, 1),
                onSliderChanged: (value) => _setValue(i, value),
                onSubmitted: () => _applyInput(i),
              ),
            ],
            if (widget.footer != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.footer!,
                style: const TextStyle(
                  color: AppColors.paletteLabel,
                  fontSize: 12,
                ),
              ),
            ],
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

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.spec,
    required this.controller,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSliderChanged,
    required this.onSubmitted,
  });

  final AdjustmentSliderSpec spec;
  final TextEditingController controller;
  final double value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          spec.label,
          style: const TextStyle(color: AppColors.paletteLabel, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _StepButton(label: '−', onPressed: onDecrement),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: value.clamp(spec.min, spec.max),
                min: spec.min,
                max: spec.max,
                divisions: spec.divisions,
                onChanged: onSliderChanged,
              ),
            ),
            const SizedBox(width: 8),
            _StepButton(label: '+', onPressed: onIncrement),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.statusText,
                  fontSize: 13,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  suffixText: spec.suffix,
                  suffixStyle: const TextStyle(color: AppColors.paletteLabel),
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
                onSubmitted: (_) => onSubmitted(),
                onEditingComplete: onSubmitted,
                onTapOutside: (_) => onSubmitted(),
              ),
            ),
          ],
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
      width: 32,
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
