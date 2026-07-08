import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/models/text_run.dart';
import 'package:vibepaint/theme/app_colors.dart';

class TextToolOptions {
  const TextToolOptions({
    this.fontFamily,
    this.fontSize = 16,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.align = TextAlign.left,
  });

  final String? fontFamily;
  final double fontSize;
  final bool bold;
  final bool italic;
  final bool underline;
  final TextAlign align;

  TextToolOptions copyWith({
    String? fontFamily,
    bool clearFontFamily = false,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    TextAlign? align,
  }) {
    return TextToolOptions(
      fontFamily: clearFontFamily ? null : (fontFamily ?? this.fontFamily),
      fontSize: fontSize ?? this.fontSize,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      align: align ?? this.align,
    );
  }
}

class TextToolOptionsControl extends StatefulWidget {
  const TextToolOptionsControl({
    super.key,
    required this.options,
    required this.onChanged,
  });

  static const double minFontSize = 8;
  static const double maxFontSize = 72;

  final TextToolOptions options;
  final ValueChanged<TextToolOptions> onChanged;

  @override
  State<TextToolOptionsControl> createState() => _TextToolOptionsControlState();
}

class _TextToolOptionsControlState extends State<TextToolOptionsControl> {
  late final TextEditingController _sizeController;

  @override
  void initState() {
    super.initState();
    _sizeController = TextEditingController(
      text: widget.options.fontSize.round().toString(),
    );
  }

  @override
  void didUpdateWidget(covariant TextToolOptionsControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.options.fontSize.round().toString();
    if (text != _sizeController.text) {
      _sizeController.text = text;
    }
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  void _setFontSize(double size) {
    final clamped = size.clamp(
      TextToolOptionsControl.minFontSize,
      TextToolOptionsControl.maxFontSize,
    );
    widget.onChanged(widget.options.copyWith(fontSize: clamped));
    _sizeController.text = clamped.round().toString();
  }

  void _applySizeInput() {
    final parsed = int.tryParse(_sizeController.text.trim());
    if (parsed == null) {
      _sizeController.text = widget.options.fontSize.round().toString();
      return;
    }
    _setFontSize(parsed.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: AppColors.paletteLabel,
      fontSize: 13,
    );
    const fieldStyle = TextStyle(
      color: AppColors.statusText,
      fontSize: 13,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Font', style: labelStyle),
        const SizedBox(width: 6),
        _FontPickerButton(
          selectedFamily: widget.options.fontFamily,
          selectedSize: widget.options.fontSize,
          onSelected: (family, size) {
            widget.onChanged(
              widget.options.copyWith(
                fontFamily: family,
                clearFontFamily: family == null,
                fontSize: size,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: TextField(
            controller: _sizeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: fieldStyle,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _fieldDecoration(),
            onSubmitted: (_) => _applySizeInput(),
            onEditingComplete: _applySizeInput,
            onTapOutside: (_) => _applySizeInput(),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<double>(
          tooltip: 'Font size',
          color: AppColors.palettePanel,
          onSelected: _setFontSize,
          itemBuilder: (context) => [
            for (final size in PaintTextFonts.sizes)
              PopupMenuItem(
                value: size,
                child: Text(
                  size.round().toString(),
                  style: const TextStyle(color: AppColors.statusText),
                ),
              ),
          ],
          child: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.statusText,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        _StyleToggle(
          label: 'B',
          tooltip: 'Bold',
          selected: widget.options.bold,
          onPressed: () => widget.onChanged(
            widget.options.copyWith(bold: !widget.options.bold),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        _StyleToggle(
          label: 'I',
          tooltip: 'Italic',
          selected: widget.options.italic,
          onPressed: () => widget.onChanged(
            widget.options.copyWith(italic: !widget.options.italic),
          ),
          textStyle: const TextStyle(fontStyle: FontStyle.italic),
        ),
        const SizedBox(width: 4),
        _StyleToggle(
          label: 'U',
          tooltip: 'Underline',
          selected: widget.options.underline,
          onPressed: () => widget.onChanged(
            widget.options.copyWith(underline: !widget.options.underline),
          ),
          textStyle: const TextStyle(decoration: TextDecoration.underline),
        ),
        const SizedBox(width: 10),
        _AlignToggle(
          icon: Icons.format_align_left,
          tooltip: 'Align left',
          selected: widget.options.align == TextAlign.left,
          onPressed: () => widget.onChanged(
            widget.options.copyWith(align: TextAlign.left),
          ),
        ),
        const SizedBox(width: 4),
        _AlignToggle(
          icon: Icons.format_align_center,
          tooltip: 'Align center',
          selected: widget.options.align == TextAlign.center,
          onPressed: () => widget.onChanged(
            widget.options.copyWith(align: TextAlign.center),
          ),
        ),
        const SizedBox(width: 4),
        _AlignToggle(
          icon: Icons.format_align_right,
          tooltip: 'Align right',
          selected: widget.options.align == TextAlign.right,
          onPressed: () => widget.onChanged(
            widget.options.copyWith(align: TextAlign.right),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    );
  }
}

class _FontPickerSelection {
  const _FontPickerSelection({
    required this.family,
    required this.fontSize,
  });

  /// Empty string means System (null family).
  final String family;
  final double fontSize;
}

class _FontPickerButton extends StatelessWidget {
  const _FontPickerButton({
    required this.selectedFamily,
    required this.selectedSize,
    required this.onSelected,
  });

  final String? selectedFamily;
  final double selectedSize;
  final void Function(String? family, double fontSize) onSelected;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showDialog<_FontPickerSelection>(
      context: context,
      builder: (context) => _FontSearchDialog(
        selectedFamily: selectedFamily,
        selectedSize: selectedSize,
      ),
    );
    if (!context.mounted || selected == null) {
      return;
    }
    onSelected(
      selected.family.isEmpty ? null : selected.family,
      selected.fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = PaintTextFonts.labelFor(selectedFamily);
    return SizedBox(
      width: 168,
      height: 32,
      child: OutlinedButton(
        onPressed: () => _openPicker(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: AppColors.statusText,
          side: const BorderSide(color: AppColors.paletteBorder),
          backgroundColor: AppColors.workspace,
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.statusText,
                  fontFamily: selectedFamily,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FontSearchDialog extends StatefulWidget {
  const _FontSearchDialog({
    required this.selectedFamily,
    required this.selectedSize,
  });

  final String? selectedFamily;
  final double selectedSize;

  @override
  State<_FontSearchDialog> createState() => _FontSearchDialogState();
}

class _FontSearchDialogState extends State<_FontSearchDialog> {
  late final TextEditingController _searchController;
  late final TextEditingController _sizeController;
  late List<({String label, String? family})> _matches;
  late String? _family;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _sizeController = TextEditingController(
      text: widget.selectedSize.round().toString(),
    );
    _matches = PaintTextFonts.options;
    _family = widget.selectedFamily;
    _fontSize = widget.selectedSize.clamp(
      TextToolOptionsControl.minFontSize,
      TextToolOptionsControl.maxFontSize,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() => _matches = PaintTextFonts.matching(query));
  }

  void _setFontSize(double size) {
    final clamped = size.clamp(
      TextToolOptionsControl.minFontSize,
      TextToolOptionsControl.maxFontSize,
    );
    setState(() {
      _fontSize = clamped;
      _sizeController.text = clamped.round().toString();
    });
  }

  void _applySizeInput() {
    final parsed = int.tryParse(_sizeController.text.trim());
    if (parsed == null) {
      _sizeController.text = _fontSize.round().toString();
      return;
    }
    _setFontSize(parsed.toDouble());
  }

  void _confirm() {
    _applySizeInput();
    Navigator.of(context).pop(
      _FontPickerSelection(
        family: _family ?? '',
        fontSize: _fontSize,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.paletteLabel),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'Font',
        style: TextStyle(color: AppColors.statusText, fontSize: 16),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppColors.statusText, fontSize: 14),
              cursorColor: AppColors.statusText,
              decoration: _fieldDecoration(
                hintText: 'Search fonts',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.paletteLabel,
                  size: 20,
                ),
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Size',
                  style: TextStyle(
                    color: AppColors.paletteLabel,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: _sizeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.statusText,
                      fontSize: 13,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration(),
                    onSubmitted: (_) => _applySizeInput(),
                    onEditingComplete: _applySizeInput,
                    onTapOutside: (_) => _applySizeInput(),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<double>(
                  tooltip: 'Font size',
                  color: AppColors.palettePanel,
                  onSelected: _setFontSize,
                  itemBuilder: (context) => [
                    for (final size in PaintTextFonts.sizes)
                      PopupMenuItem(
                        value: size,
                        child: Text(
                          size.round().toString(),
                          style: const TextStyle(color: AppColors.statusText),
                        ),
                      ),
                  ],
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.statusText,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: _matches.isEmpty
                  ? const Center(
                      child: Text(
                        'No fonts match',
                        style: TextStyle(color: AppColors.paletteLabel),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        final option = _matches[index];
                        final selected = option.family == _family;
                        return ListTile(
                          dense: true,
                          selected: selected,
                          selectedTileColor: AppColors.workspace,
                          title: Text(
                            option.label,
                            style: TextStyle(
                              color: AppColors.statusText,
                              fontFamily: option.family,
                              fontSize: 14,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.statusText,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            setState(() => _family = option.family);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.paletteLabel),
          ),
        ),
        TextButton(
          onPressed: _confirm,
          child: const Text(
            'OK',
            style: TextStyle(color: AppColors.statusText),
          ),
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
                decorationColor: AppColors.statusText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlignToggle extends StatelessWidget {
  const _AlignToggle({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

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
            child: Icon(icon, size: 16, color: AppColors.statusText),
          ),
        ),
      ),
    );
  }
}
