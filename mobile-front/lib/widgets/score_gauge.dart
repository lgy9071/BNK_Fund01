import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScoreGauge extends StatefulWidget {
  final int score;      // 원점수 (예: 0~65)
  final int maxScore;   // 만점 (예: 65)
  final Color color;    // 게이지 색
  final double size;    // 반응형 크기(기본 220)

  const ScoreGauge({
    super.key,
    required this.score,
    required this.maxScore,
    required this.color,
    this.size = 220,
  });

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.score / widget.maxScore).clamp(0.0, 1.0);
    final pct100 = (percent * 100).round();

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _GaugePainter(
                  progress: percent * _anim.value, // 0.0~1.0 애니메이션
                  color: widget.color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pct100',
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87.withOpacity(.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '위험도 점수',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87.withOpacity(.65),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset(stroke / 2, stroke / 2) &
    Size(size.width - stroke, size.height - stroke);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE9EDF7);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    // 배경 트랙
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    // 진행(시계방향)
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
