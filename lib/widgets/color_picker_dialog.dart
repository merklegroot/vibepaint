import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/theme/color_wells.dart';
import 'package:vibepaint/utils/color_picker_math.dart';

class ColorPickerResult {
  const ColorPickerResult({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;
}

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.editingTarget,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final ColorWellTarget editingTarget;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _primary;
  late Color _secondary;
  late ColorWellTarget _activeTarget;
  late Color _resetColor;
  late TextEditingController _hexController;

  ColorWheelMode _wheelMode = ColorWheelMode.hueSaturation;
  bool _showValue = true;
  bool _updatingHexField = false;

  @override
  void initState() {
    super.initState();
    _primary = widget.primaryColor;
    _secondary = widget.secondaryColor;
    _activeTarget = widget.editingTarget;
    _resetColor = _activeColor;
    _hexController = TextEditingController(text: colorToHexRgba(_activeColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _activeColor => switch (_activeTarget) {
        ColorWellTarget.primary => _primary,
        ColorWellTarget.canvasBackground => _secondary,
      };

  set _activeColor(Color color) {
    switch (_activeTarget) {
      case ColorWellTarget.primary:
        _primary = color;
      case ColorWellTarget.canvasBackground:
        _secondary = color;
    }
  }

  HSVColor get _activeHsv => HSVColor.fromColor(_activeColor);

  void _setActiveColor(Color color) {
    setState(() => _activeColor = color);
    _syncHexField();
  }

  void _setActiveHsv(HSVColor hsv) {
    _setActiveColor(hsv.toColor());
  }

  void _syncHexField() {
    _updatingHexField = true;
    _hexController.text = colorToHexRgba(_activeColor);
    _hexController.selection = TextSelection.collapsed(
      offset: _hexController.text.length,
    );
    _updatingHexField = false;
  }

  void _selectTarget(ColorWellTarget target) {
    if (_activeTarget == target) {
      return;
    }
    setState(() {
      _activeTarget = target;
      _resetColor = _activeColor;
    });
    _syncHexField();
  }

  void _resetActiveColor() {
    _setActiveColor(_resetColor);
  }

  void _swapColors() {
    setState(() {
      final primary = _primary;
      _primary = _secondary;
      _secondary = primary;
    });
    _syncHexField();
  }

  void _applyHex(String value) {
    if (_updatingHexField) {
      return;
    }
    final parsed = colorFromHexRgba(value);
    if (parsed != null) {
      _setActiveColor(parsed);
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      ColorPickerResult(primary: _primary, secondary: _secondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hsv = _activeHsv;

    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Row(
        children: [
          TextButton(
            onPressed: _resetActiveColor,
            child: const Text('Reset Color'),
          ),
          const Expanded(
            child: Text(
              'Color Picker',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.statusText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _submit,
            child: const Text('OK'),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _DialogColorWells(
                  primary: _primary,
                  secondary: _secondary,
                  activeTarget: _activeTarget,
                  onPrimaryTap: () => _selectTarget(ColorWellTarget.primary),
                  onSecondaryTap: () =>
                      _selectTarget(ColorWellTarget.canvasBackground),
                  onSwap: _swapColors,
                ),
                const SizedBox(height: 12),
                _ColorWheel(
                  hsv: hsv,
                  mode: _wheelMode,
                  showValue: _showValue,
                  onChanged: _setActiveHsv,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _showValue,
                      onChanged: (value) {
                        setState(() => _showValue = value ?? true);
                      },
                    ),
                    const Text(
                      'Show Value',
                      style: TextStyle(color: AppColors.paletteLabel),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _ModeButton(
                        label: 'Hue & Sat',
                        selected: _wheelMode == ColorWheelMode.hueSaturation,
                        onPressed: () => setState(
                          () => _wheelMode = ColorWheelMode.hueSaturation,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ModeButton(
                        label: 'Sat & Value',
                        selected: _wheelMode == ColorWheelMode.saturationValue,
                        onPressed: () => setState(
                          () => _wheelMode = ColorWheelMode.saturationValue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HexField(
                    controller: _hexController,
                    onSubmitted: _applyHex,
                    onChanged: _applyHex,
                  ),
                  const SizedBox(height: 12),
                  _ChannelSlider(
                    label: 'Hue',
                    value: hsv.hue,
                    min: 0,
                    max: 360,
                    displayValue: hsv.hue.round().toString(),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                    onChanged: (value) =>
                        _setActiveHsv(hsv.withHue(value)),
                  ),
                  _ChannelSlider(
                    label: 'Sat',
                    value: hsv.saturation * 100,
                    min: 0,
                    max: 100,
                    displayValue: (hsv.saturation * 100).round().toString(),
                    gradient: LinearGradient(
                      colors: [
                        HSVColor.fromAHSV(1, hsv.hue, 0, hsv.value).toColor(),
                        HSVColor.fromAHSV(1, hsv.hue, 1, hsv.value).toColor(),
                      ],
                    ),
                    onChanged: (value) =>
                        _setActiveHsv(hsv.withSaturation(value / 100)),
                  ),
                  _ChannelSlider(
                    label: 'Value',
                    value: hsv.value * 100,
                    min: 0,
                    max: 100,
                    displayValue: (hsv.value * 100).round().toString(),
                    gradient: LinearGradient(
                      colors: [
                        HSVColor.fromAHSV(1, hsv.hue, hsv.saturation, 0)
                            .toColor(),
                        HSVColor.fromAHSV(1, hsv.hue, hsv.saturation, 1)
                            .toColor(),
                      ],
                    ),
                    onChanged: (value) =>
                        _setActiveHsv(hsv.withValue(value / 100)),
                  ),
                  const Divider(color: AppColors.paletteBorder, height: 24),
                  _ChannelSlider(
                    label: 'Red',
                    value: _activeColor.r,
                    min: 0,
                    max: 255,
                    displayValue: _activeColor.r.round().toString(),
                    gradient: LinearGradient(
                      colors: [
                        _activeColor.withValues(alpha: 1, red: 0),
                        _activeColor.withValues(alpha: 1, red: 1),
                      ],
                    ),
                    onChanged: (value) => _setActiveColor(
                      _activeColor.withValues(alpha: 1, red: value / 255),
                    ),
                  ),
                  _ChannelSlider(
                    label: 'Green',
                    value: _activeColor.g,
                    min: 0,
                    max: 255,
                    displayValue: _activeColor.g.round().toString(),
                    gradient: LinearGradient(
                      colors: [
                        _activeColor.withValues(alpha: 1, green: 0),
                        _activeColor.withValues(alpha: 1, green: 1),
                      ],
                    ),
                    onChanged: (value) => _setActiveColor(
                      _activeColor.withValues(alpha: 1, green: value / 255),
                    ),
                  ),
                  _ChannelSlider(
                    label: 'Blue',
                    value: _activeColor.b,
                    min: 0,
                    max: 255,
                    displayValue: _activeColor.b.round().toString(),
                    gradient: LinearGradient(
                      colors: [
                        _activeColor.withValues(alpha: 1, blue: 0),
                        _activeColor.withValues(alpha: 1, blue: 1),
                      ],
                    ),
                    onChanged: (value) => _setActiveColor(
                      _activeColor.withValues(alpha: 1, blue: value / 255),
                    ),
                  ),
                  const Divider(color: AppColors.paletteBorder, height: 24),
                  _ChannelSlider(
                    label: 'Alpha',
                    value: _activeColor.a,
                    min: 0,
                    max: 255,
                    displayValue: _activeColor.a.round().toString(),
                    checkerboard: true,
                    gradient: LinearGradient(
                      colors: [
                        _activeColor.withValues(alpha: 0),
                        _activeColor.withValues(alpha: 1),
                      ],
                    ),
                    onChanged: (value) => _setActiveColor(
                      _activeColor.withValues(alpha: value / 255),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogColorWells extends StatelessWidget {
  const _DialogColorWells({
    required this.primary,
    required this.secondary,
    required this.activeTarget,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    required this.onSwap,
  });

  final Color primary;
  final Color secondary;
  final ColorWellTarget activeTarget;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    const offset = 14.0;

    return SizedBox(
      width: size + offset + 24,
      height: size + offset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: offset,
            top: offset,
            child: _DialogWell(
              color: secondary,
              size: size,
              selected: activeTarget == ColorWellTarget.canvasBackground,
              onTap: onSecondaryTap,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _DialogWell(
              color: primary,
              size: size,
              selected: activeTarget == ColorWellTarget.primary,
              onTap: onPrimaryTap,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              tooltip: 'Swap colors',
              onPressed: onSwap,
              icon: const Icon(Icons.swap_vert, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogWell extends StatelessWidget {
  const _DialogWell({
    required this.color,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final transparent = isTransparentCanvasBackground(color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: transparent ? null : color,
          border: Border.all(
            color: selected ? Colors.lightBlueAccent : Colors.black,
            width: selected ? 2 : 1,
          ),
        ),
        child: transparent
            ? CustomPaint(
                painter: const CanvasCheckerboardPainter(cellSize: 4),
                size: Size(size, size),
              )
            : null,
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor:
            selected ? AppColors.workspace : AppColors.palettePanel,
        foregroundColor: AppColors.statusText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _HexField extends StatelessWidget {
  const _HexField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Hex',
          style: TextStyle(color: AppColors.paletteLabel),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.statusText),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f#]')),
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: AppColors.workspace,
              border: OutlineInputBorder(),
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
      ],
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.gradient,
    required this.onChanged,
    this.checkerboard = false,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final Gradient gradient;
  final ValueChanged<double> onChanged;
  final bool checkerboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.paletteLabel),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (checkerboard)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CustomPaint(
                            painter: const CanvasCheckerboardPainter(cellSize: 6),
                          ),
                        ),
                      ),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.paletteBorder),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 14,
                        thumbShape: const _DropThumbShape(),
                        overlayShape: SliderComponentShape.noOverlay,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                      child: Slider(
                        value: value.clamp(min, max),
                        min: min,
                        max: max,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.statusText),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropThumbShape extends SliderComponentShape {
  const _DropThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(12, 16);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final path = Path()
      ..moveTo(center.dx, center.dy + 8)
      ..lineTo(center.dx - 6, center.dy - 4)
      ..lineTo(center.dx + 6, center.dy - 4)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

class _ColorWheel extends StatefulWidget {
  const _ColorWheel({
    required this.hsv,
    required this.mode,
    required this.showValue,
    required this.onChanged,
  });

  final HSVColor hsv;
  final ColorWheelMode mode;
  final bool showValue;
  final ValueChanged<HSVColor> onChanged;

  @override
  State<_ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<_ColorWheel> {
  static const _size = 180.0;

  void _updateFromHueSatWheel(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final delta = local - center;
    final distance = delta.distance.clamp(0.0, radius);
    final angle = math.atan2(delta.dy, delta.dx);

    final hue = (angle * 180 / math.pi + 360) % 360;
    final saturation = distance / radius;
    final value = widget.showValue ? widget.hsv.value : 1.0;

    widget.onChanged(
      HSVColor.fromAHSV(widget.hsv.alpha, hue, saturation, value),
    );
  }

  void _updateFromSatValueSquare(Offset local, Size size) {
    final padding = 8.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    final clamped = Offset(
      local.dx.clamp(rect.left, rect.right),
      local.dy.clamp(rect.top, rect.bottom),
    );

    final saturation = ((clamped.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final value = (1 - (clamped.dy - rect.top) / rect.height).clamp(0.0, 1.0);

    widget.onChanged(
      HSVColor.fromAHSV(widget.hsv.alpha, widget.hsv.hue, saturation, value),
    );
  }

  void _handlePan(Offset local, Size size) {
    switch (widget.mode) {
      case ColorWheelMode.hueSaturation:
        _updateFromHueSatWheel(local, size);
      case ColorWheelMode.saturationValue:
        _updateFromSatValueSquare(local, size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => _handlePan(details.localPosition, const Size(_size, _size)),
      onPanUpdate: (details) => _handlePan(details.localPosition, const Size(_size, _size)),
      child: CustomPaint(
        size: const Size(_size, _size),
        painter: _ColorWheelPainter(
          hsv: widget.hsv,
          mode: widget.mode,
          showValue: widget.showValue,
        ),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  const _ColorWheelPainter({
    required this.hsv,
    required this.mode,
    required this.showValue,
  });

  final HSVColor hsv;
  final ColorWheelMode mode;
  final bool showValue;

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case ColorWheelMode.hueSaturation:
        _paintHueSatWheel(canvas, size);
      case ColorWheelMode.saturationValue:
        _paintSatValueSquare(canvas, size);
    }
    _paintSelector(canvas, size);
  }

  void _paintHueSatWheel(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final displayValue = showValue ? hsv.value : 1.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            for (var hue = 0; hue <= 360; hue++)
              HSVColor.fromAHSV(1, hue.toDouble(), 1, displayValue).toColor(),
          ],
        ).createShader(rect),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect)
        ..blendMode = BlendMode.srcOver,
    );
  }

  void _paintSatValueSquare(Canvas canvas, Size size) {
    const padding = 8.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            HSVColor.fromAHSV(1, hsv.hue, 0, 1).toColor(),
            HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
          ],
        ).createShader(rect)
        ..blendMode = BlendMode.multiply,
    );
  }

  void _paintSelector(Canvas canvas, Size size) {
    late Offset selectorCenter;

    switch (mode) {
      case ColorWheelMode.hueSaturation:
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.min(size.width, size.height) / 2 - 8;
        final angle = hsv.hue * math.pi / 180;
        final distance = hsv.saturation * radius;
        selectorCenter = Offset(
          center.dx + math.cos(angle) * distance,
          center.dy + math.sin(angle) * distance,
        );
      case ColorWheelMode.saturationValue:
        const padding = 8.0;
        final rect = Rect.fromLTWH(
          padding,
          padding,
          size.width - padding * 2,
          size.height - padding * 2,
        );
        selectorCenter = Offset(
          rect.left + hsv.saturation * rect.width,
          rect.top + (1 - hsv.value) * rect.height,
        );
    }

    final selector = Rect.fromCenter(center: selectorCenter, width: 10, height: 10);
    canvas.drawRect(
      selector,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      selector,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.hsv != hsv ||
        oldDelegate.mode != mode ||
        oldDelegate.showValue != showValue;
  }
}
