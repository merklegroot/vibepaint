import 'package:flutter/material.dart';
import 'package:vibepaint/menus/platform_artistic_menus.dart';

List<PlatformMenuItemGroup> buildEffectsPlatformMenuGroups({
  required VoidCallback onInkSketch,
  required VoidCallback onOilPainting,
  required VoidCallback onPencilSketch,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenu(
          label: 'Artistic',
          menus: buildArtisticPlatformMenuGroups(
            onInkSketch: onInkSketch,
            onOilPainting: onOilPainting,
            onPencilSketch: onPencilSketch,
          ),
        ),
      ],
    ),
  ];
}
