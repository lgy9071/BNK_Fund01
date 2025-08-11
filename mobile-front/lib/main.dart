import 'package:flutter/material.dart';
import 'screens/main_scaffold.dart';
import 'screens/qna_compose_screen.dart';
import 'screens/qna_list_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/fund_guide_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BNK Fund',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0064FF)),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0064FF), brightness: Brightness.dark),
      ),
      home: const MainScaffold(),
      routes: {
        '/qna/compose': (_) => const QnaComposeScreen(),
        '/qna/list'   : (_) => const QnaListScreen(),
        '/faq'        : (_) => const FaqScreen(),
        '/guide'      : (_) => const FundGuideScreen(),
      },
    );
  }
}