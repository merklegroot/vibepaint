import 'package:flutter/material.dart';
import 'package:vibepaint/theme/app_colors.dart';

/// Minimal file actions for Android/iOS (no desktop menu bar).
class MobileFileBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileFileBar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    this.isDirty = false,
    this.documentName,
  });

  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final bool isDirty;
  final String? documentName;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final title = documentName == null
        ? 'VibePaint'
        : '${isDirty ? '*' : ''}$documentName';

    return AppBar(
      backgroundColor: AppColors.palettePanel,
      foregroundColor: AppColors.statusText,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          tooltip: 'New',
          onPressed: onNew,
          icon: const Icon(Icons.note_add_outlined),
        ),
        IconButton(
          tooltip: 'Open',
          onPressed: onOpen,
          icon: const Icon(Icons.folder_open_outlined),
        ),
        IconButton(
          tooltip: 'Save',
          onPressed: onSave,
          icon: const Icon(Icons.save_outlined),
        ),
      ],
    );
  }
}
