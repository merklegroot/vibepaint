import 'package:flutter/material.dart';
import 'package:vibepaint/menus/platform_artistic_menus.dart';
import 'package:vibepaint/menus/platform_blur_menus.dart';
import 'package:vibepaint/menus/platform_color_menus.dart';
import 'package:vibepaint/menus/platform_distort_menus.dart';
import 'package:vibepaint/menus/platform_photo_menus.dart';
import 'package:vibepaint/menus/platform_render_menus.dart';
import 'package:vibepaint/menus/platform_stylize_menus.dart';

List<PlatformMenuItemGroup> buildEffectsPlatformMenuGroups({
  required VoidCallback onGlow,
  required VoidCallback onSharpen,
  required VoidCallback onSoftenPortrait,
  required VoidCallback onInkSketch,
  required VoidCallback onOilPainting,
  required VoidCallback onPencilSketch,
  required VoidCallback onFragment,
  required VoidCallback onGaussianBlur,
  required VoidCallback onMotionBlur,
  required VoidCallback onRadialBlur,
  required VoidCallback onUnfocus,
  required VoidCallback onZoomBlur,
  required VoidCallback onBulge,
  required VoidCallback onFrostedGlass,
  required VoidCallback onPixelate,
  required VoidCallback onPolarInversion,
  required VoidCallback onTileReflection,
  required VoidCallback onTwist,
  required VoidCallback onClouds,
  required VoidCallback onJuliaFractal,
  required VoidCallback onMandelbrotFractal,
  required VoidCallback onEdgeDetect,
  required VoidCallback onEmboss,
  required VoidCallback onOutline,
  required VoidCallback onRelief,
  required VoidCallback onDithering,
}) {
  return [
    PlatformMenuItemGroup(
      members: [
        PlatformMenu(
          label: 'Photo',
          menus: buildPhotoPlatformMenuGroups(
            onGlow: onGlow,
            onSharpen: onSharpen,
            onSoftenPortrait: onSoftenPortrait,
          ),
        ),
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
          label: 'Distort',
          menus: buildDistortPlatformMenuGroups(
            onBulge: onBulge,
            onFrostedGlass: onFrostedGlass,
            onPixelate: onPixelate,
            onPolarInversion: onPolarInversion,
            onTileReflection: onTileReflection,
            onTwist: onTwist,
          ),
        ),
        PlatformMenu(
          label: 'Render',
          menus: buildRenderPlatformMenuGroups(
            onClouds: onClouds,
            onJuliaFractal: onJuliaFractal,
            onMandelbrotFractal: onMandelbrotFractal,
          ),
        ),
        PlatformMenu(
          label: 'Stylize',
          menus: buildStylizePlatformMenuGroups(
            onEdgeDetect: onEdgeDetect,
            onEmboss: onEmboss,
            onOutline: onOutline,
            onRelief: onRelief,
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
