import 'package:flutter/material.dart';

List<PlatformMenuItemGroup> buildArtisticPlatformMenuGroups({
  required VoidCallback onInkSketch,
  required VoidCallback onOilPainting,
  required VoidCallback onPencilSketch,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(
          label: 'Ink Sketch...',
          onSelected: onInkSketch,
        ),
        PlatformMenuItem(
          label: 'Oil Painting...',
          onSelected: onOilPainting,
        ),
        PlatformMenuItem(
          label: 'Pencil Sketch...',
          onSelected: onPencilSketch,
        ),
      ],
    ),
  ];
}
