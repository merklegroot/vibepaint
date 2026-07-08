import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibepaint/models/image_file_format.dart';
import 'package:vibepaint/theme/app_colors.dart';

class SaveImageRequest {
  const SaveImageRequest({
    required this.path,
    required this.format,
  });

  final String path;
  final ImageFileFormat format;
}

Future<SaveImageRequest?> showSaveImageDialog(
  BuildContext context, {
  required String? documentPath,
  required ImageFileFormat initialFormat,
}) {
  return showDialog<SaveImageRequest>(
    context: context,
    builder: (context) => _SaveImageDialog(
      documentPath: documentPath,
      initialFormat: initialFormat,
    ),
  );
}

class _SaveImageDialog extends StatefulWidget {
  const _SaveImageDialog({
    required this.documentPath,
    required this.initialFormat,
  });

  final String? documentPath;
  final ImageFileFormat initialFormat;

  @override
  State<_SaveImageDialog> createState() => _SaveImageDialogState();
}

class _SaveImageDialogState extends State<_SaveImageDialog> {
  late ImageFileFormat _selectedFormat = widget.initialFormat;
  late final TextEditingController _nameController;
  late String _directory;

  @override
  void initState() {
    super.initState();
    _directory = _initialDirectory(widget.documentPath);
    _nameController = TextEditingController(
      text: widget.documentPath == null
          ? 'Untitled'
          : fileNameStemFromPath(widget.documentPath!),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateFormat(ImageFileFormat format) {
    setState(() => _selectedFormat = format);
  }

  Future<void> _browseDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose folder',
      initialDirectory: _directory,
    );
    if (directory == null) {
      return;
    }

    setState(() => _directory = directory);
  }

  void _save() {
    final stem = _nameController.text.trim();
    if (stem.isEmpty) {
      return;
    }

    final fileName = '$stem.${_selectedFormat.defaultExtension}';
    final path = joinDirectoryAndFile(_directory, fileName);
    Navigator.of(context).pop(
      SaveImageRequest(path: path, format: _selectedFormat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.palettePanel,
      title: const Text(
        'Save As',
        style: TextStyle(color: AppColors.statusText),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'File name',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.statusText),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.workspace,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: AppColors.paletteBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: AppColors.paletteBorder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Save as type',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.workspace,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.paletteBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ImageFileFormat>(
                  value: _selectedFormat,
                  isExpanded: true,
                  dropdownColor: AppColors.palettePanel,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  style: const TextStyle(color: AppColors.statusText),
                  items: [
                    for (final format in ImageFileFormat.values)
                      DropdownMenuItem(
                        value: format,
                        child: Text(format.menuLabel),
                      ),
                  ],
                  onChanged: (format) {
                    if (format != null) {
                      _updateFormat(format);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFormat.description,
              style: const TextStyle(
                color: AppColors.paletteLabel,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Save in',
              style: TextStyle(color: AppColors.paletteLabel, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _directory,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.statusText,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _browseDirectory,
                  child: const Text('Browse…'),
                ),
              ],
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
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _initialDirectory(String? documentPath) {
  final parent = parentDirectoryPath(documentPath);
  if (parent != null) {
    return parent;
  }

  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    return home;
  }

  return Directory.current.path;
}

String joinDirectoryAndFile(String directory, String fileName) {
  if (directory.endsWith(Platform.pathSeparator)) {
    return '$directory$fileName';
  }
  return '$directory${Platform.pathSeparator}$fileName';
}

String? parentDirectoryPath(String? path) {
  if (path == null) {
    return null;
  }

  final separator = path.lastIndexOf(Platform.pathSeparator);
  if (separator <= 0) {
    return null;
  }

  return path.substring(0, separator);
}

bool get useNativeSaveFormatPicker =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows;
