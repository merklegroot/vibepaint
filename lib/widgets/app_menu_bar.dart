import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/theme/app_colors.dart';

/// In-window File menu for Windows and Linux.
class AppMenuBar extends StatelessWidget {
  const AppMenuBar({
    super.key,
    required this.canNew,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
  });

  final bool canNew;
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (!useInWindowFileMenu) {
      return const SizedBox.shrink();
    }

    return MenuBar(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
      ),
      children: [
        SubmenuButton(
          style: ButtonStyle(
            foregroundColor: const WidgetStatePropertyAll(AppColors.statusText),
            overlayColor: WidgetStatePropertyAll(
              AppColors.statusText.withValues(alpha: 0.08),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: canNew ? onNew : null,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyN),
              child: const Text('New'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: onOpen,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyO),
              child: const Text('Open...'),
            ),
            MenuItemButton(
              onPressed: onSave,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyS),
              child: const Text('Save...'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Exit'),
            ),
          ],
          child: const Text('File'),
        ),
      ],
    );
  }
}
