import 'package:flutter/material.dart';
import 'package:mobile_front/screens/cdd/cdd_screen.dart';

void main() {
  runApp(DevApp());
}

class DevApp extends StatelessWidget {
  const DevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev - Your Screen',
      home: CddScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}