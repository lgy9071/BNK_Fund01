import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;
  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primaryBlue, // 입력 커서 색
          selectionHandleColor: Color(0xFF00067D), // ✅ 손잡이 색상
        ),
      ),
      home: SplashScreen(), // 🔥 시작점
    );
  }
}