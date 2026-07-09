import 'package:flutter/material.dart';

List<PlatformMenuItemGroup> buildStylizePlatformMenuGroups({
  required VoidCallback onEdgeDetect,
  required VoidCallback onEmboss,
  required VoidCallback onOutline,
  required VoidCallback onRelief,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenuItem(label: 'Edge Detect...', onSelected: onEdgeDetect),
        PlatformMenuItem(label: 'Emboss...', onSelected: onEmboss),
        PlatformMenuItem(label: 'Outline...', onSelected: onOutline),
        PlatformMenuItem(label: 'Relief...', onSelected: onRelief),
      ],
    ),
  ];
}
