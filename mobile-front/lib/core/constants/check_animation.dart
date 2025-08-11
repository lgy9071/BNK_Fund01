import 'dart:math' as math; // ✅ pi 사용
import 'package:flutter/material.dart';

class CheckAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const CheckAnimation({
    Key? key,
    required this.color,
    this.size = 60,
    this.duration = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  State<CheckAnimation> createState() => _CheckAnimationState();
}

class _CheckAnimationState extends State<CheckAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _rotation = Tween<double>(begin: 0.0, end: 2.0 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_rotation.value),
          child: child,
        );
      },
      child: CircleAvatar(
        radius: widget.size / 2,
        backgroundColor: widget.color,
        child: Icon(Icons.check, color: Colors.white, size: widget.size),
      ),
    );
  }
}
