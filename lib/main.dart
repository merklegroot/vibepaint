import 'package:flutter/material.dart';
import 'package:vibepaint/bootstrap/file_picker_init.dart';
import 'package:vibepaint/screens/paint_screen.dart';

void main() {
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
      ),
      home: home ?? const PaintScreen(),
    );
  }
}
