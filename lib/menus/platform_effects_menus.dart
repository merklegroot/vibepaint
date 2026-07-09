import 'package:flutter/material.dart';
import 'package:vibepaint/menus/platform_artistic_menus.dart';
import 'package:vibepaint/menus/platform_blur_menus.dart';
import 'package:vibepaint/menus/platform_color_menus.dart';

List<PlatformMenuItemGroup> buildEffectsPlatformMenuGroups({
  required VoidCallback onInkSketch,
  required VoidCallback onOilPainting,
  required VoidCallback onPencilSketch,
  required VoidCallback onFragment,
  required VoidCallback onGaussianBlur,
  required VoidCallback onMotionBlur,
  required VoidCallback onRadialBlur,
  required VoidCallback onUnfocus,
  required VoidCallback onZoomBlur,
  required VoidCallback onDithering,
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
        PlatformMenu(
          label: 'Blurs',
          menus: buildBlurPlatformMenuGroups(
            onFragment: onFragment,
            onGaussianBlur: onGaussianBlur,
            onMotionBlur: onMotionBlur,
            onRadialBlur: onRadialBlur,
            onUnfocus: onUnfocus,
            onZoomBlur: onZoomBlur,
          ),
        ),
        PlatformMenu(
          label: 'Color',
          menus: buildColorPlatformMenuGroups(
            onDithering: onDithering,
          ),
        ),
      ],
    ),
  ];
}
