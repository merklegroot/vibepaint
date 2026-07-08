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
    required this.onCropToSelection,
    required this.onAutoCrop,
    required this.onResizeImage,
    required this.onResizeCanvas,
    required this.onFlipHorizontal,
    required this.onFlipVertical,
    required this.onRotate90Clockwise,
    required this.onRotate90CounterClockwise,
    required this.onRotate180,
    required this.onFlatten,
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
  final VoidCallback? onCropToSelection;
  final VoidCallback onAutoCrop;
  final VoidCallback onResizeImage;
  final VoidCallback onResizeCanvas;
  final VoidCallback onFlipHorizontal;
  final VoidCallback onFlipVertical;
  final VoidCallback onRotate90Clockwise;
  final VoidCallback onRotate90CounterClockwise;
  final VoidCallback onRotate180;
  final VoidCallback onFlatten;

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
        SubmenuButton(
          style: menuStyle,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: onCropToSelection,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyX,
                shift: true,
              ),
              child: const Text('Crop to Selection'),
            ),
            MenuItemButton(
              onPressed: onAutoCrop,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyX,
                control: true,
                alt: true,
              ),
              child: const Text('Auto Crop'),
            ),
            MenuItemButton(
              onPressed: onResizeImage,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyR),
              child: const Text('Resize Image...'),
            ),
            MenuItemButton(
              onPressed: onResizeCanvas,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyR,
                shift: true,
              ),
              child: const Text('Resize Canvas...'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: onFlipHorizontal,
              child: const Text('Flip Horizontal'),
            ),
            MenuItemButton(
              onPressed: onFlipVertical,
              child: const Text('Flip Vertical'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: onRotate90Clockwise,
              child: const Text('Rotate 90° Clockwise'),
            ),
            MenuItemButton(
              onPressed: onRotate90CounterClockwise,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyG),
              child: const Text('Rotate 90° Counter-Clockwise'),
            ),
            MenuItemButton(
              onPressed: onRotate180,
              shortcut: platformMenuShortcut(LogicalKeyboardKey.keyJ),
              child: const Text('Rotate 180°'),
            ),
            const Divider(height: 1),
            MenuItemButton(
              onPressed: onFlatten,
              shortcut: platformMenuShortcut(
                LogicalKeyboardKey.keyF,
                shift: true,
              ),
              child: const Text('Flatten'),
            ),
          ],
          child: const Text('Image'),
        ),
      ],
    );
  }
}
