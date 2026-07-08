import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibepaint/menus/menu_shortcuts.dart';
import 'package:vibepaint/theme/app_colors.dart';

/// In-window File and Edit menus for Windows and Linux.
class AppMenuBar extends StatelessWidget {
  const AppMenuBar({
    super.key,
    required this.canNew,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onSaveAs,
    required this.onSelectAll,
    required this.onDeselect,
    required this.onInvertSelection,
    required this.onDeleteSelection,
    required this.hasSelection,
  });

  final bool canNew;
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onSaveAs;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselect;
  final VoidCallback onInvertSelection;
  final VoidCallback onDeleteSelection;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    if (!useInWindowFileMenu) {
      return const SizedBox.shrink();
    }

    final menuStyle = ButtonStyle(
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
    );

    return MenuBar(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
      ),
      children: [
        SubmenuButton(
          style: menuStyle,
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
              child: const Text('Save'),
            ),
            MenuItemButton(
              onPressed: onSaveAs,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyS,
                shift: true,
              ),
              child: const Text('Save As...'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Exit'),
            ),
          ],
          child: const Text('File'),
        ),
        SubmenuButton(
          style: menuStyle,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: onSelectAll,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyA),
              child: const Text('Select All'),
            ),
            MenuItemButton(
              onPressed: hasSelection ? onDeselect : null,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyD),
              child: const Text('Deselect'),
            ),
            MenuItemButton(
              onPressed: hasSelection ? onInvertSelection : null,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyI,
                shift: true,
                control: true,
              ),
              child: const Text('Invert Selection'),
            ),
            MenuItemButton(
              onPressed: hasSelection ? onDeleteSelection : null,
              shortcut: const SingleActivator(LogicalKeyboardKey.delete),
              child: const Text('Delete Selection'),
            ),
          ],
          child: const Text('Edit'),
        ),
      ],
    );
  }
}
