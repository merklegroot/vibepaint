import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';

class CloudsSettings {
  const CloudsSettings({
    required this.scale,
    required this.power,
    required this.seed,
  });

  final double scale;
  final double power;
  final int seed;
}

class CloudsDialog extends StatefulWidget {
  const CloudsDialog({
    super.key,
    required this.onSettingsChanged,
    this.initialSeed,
  });

  final ValueChanged<CloudsSettings> onSettingsChanged;
  final int? initialSeed;

  @override
  State<CloudsDialog> createState() => _CloudsDialogState();
}

class _CloudsDialogState extends State<CloudsDialog> {
  double _scale = 50;
  double _power = 50;
  late int _seed;

  @override
  void initState() {
    super.initState();
    _seed = widget.initialSeed ?? DateTime.now().millisecondsSinceEpoch % 100000;
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  CloudsSettings get _settings => CloudsSettings(
        scale: _scale,
        power: _power,
        seed: _seed,
      );

  void _notifyChanged() {
    widget.onSettingsChanged(_settings);
  }

  void _reseed() {
    setState(() {
      _seed = DateTime.now().millisecondsSinceEpoch % 100000;
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'Clouds',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SliderRow(
              label: 'Scale',
              value: _scale,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() => _scale = value);
                _notifyChanged();
              },
            ),
            const SizedBox(height: 12),
            _SliderRow(
              label: 'Power',
              value: _power,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() => _power = value);
                _notifyChanged();
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _reseed,
              child: const Text('Reseed'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Uses the primary and secondary palette colors.',
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
          onPressed: () => Navigator.of(context).pop(_settings),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class MandelbrotSettings {
  const MandelbrotSettings({
    required this.factor,
    required this.quality,
    required this.zoom,
    required this.invert,
  });

  final double factor;
  final double quality;
  final double zoom;
  final bool invert;
}

class MandelbrotDialog extends StatefulWidget {
  const MandelbrotDialog({
    super.key,
    required this.onSettingsChanged,
  });

  final ValueChanged<MandelbrotSettings> onSettingsChanged;

  @override
  State<MandelbrotDialog> createState() => _MandelbrotDialogState();
}

class _MandelbrotDialogState extends State<MandelbrotDialog> {
  double _factor = 50;
  double _quality = 50;
  double _zoom = 50;
  bool _invert = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  MandelbrotSettings get _settings => MandelbrotSettings(
        factor: _factor,
        quality: _quality,
        zoom: _zoom,
        invert: _invert,
      );

  void _notifyChanged() {
    widget.onSettingsChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'Mandelbrot Fractal',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SliderRow(
              label: 'Factor',
              value: _factor,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() => _factor = value);
                _notifyChanged();
              },
            ),
            const SizedBox(height: 12),
            _SliderRow(
              label: 'Quality',
              value: _quality,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() => _quality = value);
                _notifyChanged();
              },
            ),
            const SizedBox(height: 12),
            _SliderRow(
              label: 'Zoom',
              value: _zoom,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() => _zoom = value);
                _notifyChanged();
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Invert colors',
                style: TextStyle(color: AppColors.statusText, fontSize: 13),
              ),
              value: _invert,
              activeColor: AppColors.statusText,
              checkColor: AppColors.workspace,
              onChanged: (value) {
                setState(() => _invert = value ?? false);
                _notifyChanged();
              },
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
          onPressed: () => Navigator.of(context).pop(_settings),
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
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.paletteLabel, fontSize: 13),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
