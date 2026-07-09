import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/image_color_effects.dart';

class DitheringSettings {
  const DitheringSettings({
    required this.colorLevels,
    required this.kernel,
    required this.serpentine,
  });

  final int colorLevels;
  final img.DitherKernel kernel;
  final bool serpentine;
}

class DitheringDialog extends StatefulWidget {
  const DitheringDialog({super.key, required this.onSettingsChanged});

  final ValueChanged<DitheringSettings> onSettingsChanged;

  @override
  State<DitheringDialog> createState() => _DitheringDialogState();
}

class _DitheringDialogState extends State<DitheringDialog> {
  int _colorLevels = 16;
  img.DitherKernel _kernel = img.DitherKernel.floydSteinberg;
  bool _serpentine = false;
  late final TextEditingController _levelsController;

  @override
  void initState() {
    super.initState();
    _levelsController = TextEditingController(text: _colorLevels.toString());
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  @override
  void dispose() {
    _levelsController.dispose();
    super.dispose();
  }

  DitheringSettings get _settings => DitheringSettings(
    colorLevels: _colorLevels,
    kernel: _kernel,
    serpentine: _serpentine,
  );

  void _notifyChanged() {
    widget.onSettingsChanged(_settings);
  }

  void _setColorLevels(int value) {
    final clamped = value.clamp(2, 256);
    setState(() {
      _colorLevels = clamped;
      _levelsController.text = clamped.toString();
    });
    _notifyChanged();
  }

  void _applyLevelsInput() {
    final parsed = int.tryParse(_levelsController.text.trim());
    if (parsed == null) {
      _levelsController.text = _colorLevels.toString();
      return;
    }
    _setColorLevels(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'Dithering',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Color levels',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _StepButton(
                  label: '−',
                  onPressed: () => _setColorLevels(_colorLevels - 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _colorLevels.toDouble(),
                    min: 2,
                    max: 256,
                    divisions: 254,
                    onChanged: (value) => _setColorLevels(value.round()),
                  ),
                ),
                const SizedBox(width: 8),
                _StepButton(
                  label: '+',
                  onPressed: () => _setColorLevels(_colorLevels + 1),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: _levelsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.statusText,
                      fontSize: 13,
                    ),
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
                    onSubmitted: (_) => _applyLevelsInput(),
                    onEditingComplete: _applyLevelsInput,
                    onTapOutside: (_) => _applyLevelsInput(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Method',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<img.DitherKernel>(
              initialValue: _kernel,
              dropdownColor: AppColors.workspace,
              style: const TextStyle(color: AppColors.statusText),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.workspace,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.paletteBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.paletteBorder),
                ),
              ),
              items: [
                for (final kernel in ditherKernelOptions)
                  DropdownMenuItem(
                    value: kernel,
                    child: Text(ditherKernelLabel(kernel)),
                  ),
              ],
              onChanged: (kernel) {
                if (kernel == null) {
                  return;
                }
                setState(() => _kernel = kernel);
                _notifyChanged();
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Serpentine',
                style: TextStyle(color: AppColors.statusText, fontSize: 13),
              ),
              value: _serpentine,
              activeColor: AppColors.statusText,
              checkColor: AppColors.workspace,
              onChanged: (value) {
                setState(() => _serpentine = value ?? false);
                _notifyChanged();
              },
            ),
            const Text(
              'Preview updates on the canvas.',
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
          onPressed: () {
            _applyLevelsInput();
            Navigator.of(context).pop(_settings);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onPressed});

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
        child: Text(label, style: const TextStyle(fontSize: 18, height: 1)),
      ),
    );
  }
}
