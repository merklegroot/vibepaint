import 'package:flutter/material.dart';
import 'package:vibepaint/screens/paint_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VibePaintApp());
}

class VibePaintApp extends StatelessWidget {
  const VibePaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibePaint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const PaintScreen(),
    );
  }
}
