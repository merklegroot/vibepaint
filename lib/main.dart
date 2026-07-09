import 'package:flutter/material.dart';
import 'package:vibepaint/bootstrap/file_picker_init.dart';
import 'package:vibepaint/screens/paint_screen.dart';
import 'package:vibepaint/theme/app_colors.dart';
import 'package:vibepaint/utils/app_version.dart';
import 'package:vibepaint/utils/native_window_title.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ensureNativeWindowManager(),
    ensureAppVersionLoaded(),
  ]);
  ensureFilePickerInitialized();
  runApp(const VibePaintApp());
}

class VibePaintApp extends StatelessWidget {
  const VibePaintApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibePaint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        menuBarTheme: const MenuBarThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
          ),
        ),
        menuTheme: const MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.palettePanel),
            surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
        menuButtonTheme: MenuButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.statusText.withValues(alpha: 0.38);
              }
              return AppColors.statusText;
            }),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)) {
                return AppColors.statusText.withValues(alpha: 0.08);
              }
              return null;
            }),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      home: home ?? const PaintScreen(),
    );
  }
}
