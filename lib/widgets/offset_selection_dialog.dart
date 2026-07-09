import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/theme/app_colors.dart';

class OffsetSelectionDialog extends StatefulWidget {
  const OffsetSelectionDialog({super.key});

  @override
  State<OffsetSelectionDialog> createState() => _OffsetSelectionDialogState();
}

class _OffsetSelectionDialogState extends State<OffsetSelectionDialog> {
  double _horizontal = 0;
  double _vertical = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'Offset Selection',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SliderRow(
              label: 'Horizontal',
              value: _horizontal,
              onChanged: (value) => setState(() => _horizontal = value),
            ),
            const SizedBox(height: 12),
            _SliderRow(
              label: 'Vertical',
              value: _vertical,
              onChanged: (value) => setState(() => _vertical = value),
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
          onPressed: () => Navigator.of(
            context,
          ).pop(Offset(_horizontal.roundToDouble(), _vertical.roundToDouble())),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.paletteLabel, fontSize: 13),
            ),
            const Spacer(),
            Text(
              value.round().toString(),
              style: const TextStyle(color: AppColors.statusText, fontSize: 13),
            ),
          ],
        ),
        Slider(
          value: value,
          min: -200,
          max: 200,
          divisions: 400,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
