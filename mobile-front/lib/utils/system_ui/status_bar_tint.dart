import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusBarTint extends StatelessWidget {
  final Color color;
  final Brightness iconBrightness; // Android
  final Brightness statusBarBrightness; // iOS
  final Widget child;

  const StatusBarTint({
    super.key,
    required this.color,
    this.iconBrightness = Brightness.dark,
    this.statusBarBrightness = Brightness.light,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: iconBrightness, // Android
        statusBarBrightness: statusBarBrightness, // iOS
      ),
      child: child,
    );
  }
}