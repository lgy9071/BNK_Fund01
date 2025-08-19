import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class ScoreGauge extends StatefulWidget {
  final int score;
  final int maxScore;
  final Color color;
  final double size;
  final double thickness;
  final double progressExtraThickness;
  final Color trackColor;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;

  const ScoreGauge({
    super.key,
    required this.score,
    required this.maxScore,
    required this.color,
    this.size = 220,
    this.thickness = 16,
    this.progressExtraThickness = 2.0,
    this.trackColor = const Color(0xFFE9EDF7),
    this.gradientColors,
    this.gradientStops,
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

    // 🔥 살짝 지연 후 애니메이션 시작 (UI 먼저 뜨고 차트 실행)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void didUpdateWidget(covariant ScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score || oldWidget.maxScore != widget.maxScore) {
      _ac
        ..reset()
        ..forward();
    }
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
    final gaugeH = widget.size * 0.66;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final p = percent * _anim.value;
        return SizedBox(
          width: widget.size,
          height: gaugeH,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, gaugeH),
                painter: _SemiGaugePainter(
                  progress: p,
                  trackColor: widget.trackColor,
                  baseColor: widget.color,
                  thickness: widget.thickness,
                  progressExtraThickness: widget.progressExtraThickness,
                  gradientColors: widget.gradientColors,
                  gradientStops: widget.gradientStops,
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 60,),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$pct100',
                          style: const TextStyle(
                            fontSize: 46,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: AppColors.fontColor,
                          ),
                        ),
                        const TextSpan(
                          text: ' / 100',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '위험도 점수',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.fontColor,
                      fontWeight: FontWeight.w700,
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

class _SemiGaugePainter extends CustomPainter {
  final double progress;                 // 0.0 ~ 1.0
  final double thickness;                // 트랙 두께
  final double progressExtraThickness;   // 진행선 두께 가산
  final Color trackColor;
  final Color baseColor;                 // gradientColors 없을 때 사용
  final List<Color>? gradientColors;
  final List<double>? gradientStops;

  _SemiGaugePainter({
    required this.progress,
    required this.thickness,
    required this.progressExtraThickness,
    required this.trackColor,
    required this.baseColor,
    required this.gradientColors,
    required this.gradientStops,
  });

  List<double> _autoStops(int n) {
    if (n <= 1) return const [0.0, 1.0];
    final step = 1.0 / (n - 1);
    return List<double>.generate(n, (i) => i * step);
  }

  // 상단 반원(왼→오른)을 t=0..1로 보고 해당 위치 색 샘플
  Color _sampleColor(List<Color> colors, List<double> stops, double t) {
    t = t.clamp(0.0, 1.0);
    if (t <= stops.first) return colors.first;
    if (t >= stops.last) return colors.last;
    int hi = 1;
    while (hi < stops.length && t > stops[hi]) hi++;
    final lo = hi - 1;
    final span = (stops[hi] - stops[lo]).clamp(1e-6, 1.0);
    final lt = ((t - stops[lo]) / span).clamp(0.0, 1.0);
    return Color.lerp(colors[lo], colors[hi], lt)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final trackStroke = thickness;
    final progressStroke = thickness + progressExtraThickness;

    // 진행선 기준으로 패딩된 원
    final diameter = size.width - progressStroke;
    final rect = Rect.fromLTWH(
      progressStroke / 2,
      progressStroke / 2,
      diameter,
      diameter,
    );
    final r = rect.width / 2;

    // 각도: 상단 반원 (왼쪽→오른쪽)
    const startAngle = math.pi;   // 9시
    const fullSweep  = math.pi;   // 시계방향 반원

    // 배경 트랙
    final trackPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackStroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, startAngle, fullSweep, false, trackPaint);

    // 본체(그라데이션) — butt로 그림(이음새 영향 제거)
    final gradPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressStroke
      ..strokeCap = StrokeCap.butt;

    // 캡(양끝 짧은 라운드 아크)
    final capPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressStroke
      ..strokeCap = StrokeCap.round;

    // 셰이더 준비
    List<Color> colors;
    List<double> stops;
    if (gradientColors != null && gradientColors!.isNotEmpty) {
      colors = List<Color>.from(gradientColors!);
      stops  = (gradientStops != null && gradientStops!.length == colors.length)
          ? List<double>.from(gradientStops!)
          : _autoStops(colors.length);

      // 오른쪽 끝이 마지막 색으로 끝나도록 보장
      gradPaint.shader = SweepGradient(
        startAngle: math.pi,              // 9시
        endAngle: 2 * math.pi,            // 3시
        colors: [...colors, colors.last],
        stops:  [...stops,  1.0],
        tileMode: TileMode.clamp,
      ).createShader(rect);
    } else {
      colors = [baseColor, baseColor];
      stops  = const [0.0, 1.0];
      gradPaint.color = baseColor;
    }

    // 진행 각도
    final p = progress.clamp(0.0, 1.0);
    final sweep = fullSweep * p;
    if (sweep <= 0) return;

    // 1) 본체(그라데이션, butt)
    canvas.drawArc(rect, startAngle, sweep, false, gradPaint);

    // 2) 양끝 라운드 캡 — '아주 짧게' + '정확한 색'으로
    //    tiny 길이를 라운드캡 각도의 0.35배로 축소 → 덧칠 티 최소화
    final capAngle = (progressStroke / 2) / r;   // 라운드캡이 차지하는 각도
    final tiny = math.min(sweep / 2, capAngle * 0.05);

    if (tiny > 0) {
      // t 매핑: 상단 반원(왼→오른) 0..1 에서 각도 기반
      // 본체 범위는 startAngle..(startAngle+sweep)
      // - 시작 캡 중앙: startAngle + tiny/2  -> tStart
      // - 끝   캡 중앙: startAngle + sweep - tiny/2 -> tEnd
      final tStart = (tiny / 2) / fullSweep;                // 0..1
      final tEnd   = (sweep - tiny / 2) / fullSweep;        // 0..1, p와 정합

      final startColor = _sampleColor(colors, stops, tStart);
      final endColor   = _sampleColor(colors, stops, tEnd);

      // 시작 캡
      capPaint.color = startColor;
      canvas.drawArc(rect, startAngle, tiny, false, capPaint);

      // 끝 캡
      capPaint.color = endColor;
      final endAngle = startAngle + sweep;
      canvas.drawArc(rect, endAngle - tiny, tiny, false, capPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter old) {
    return old.progress != progress ||
        old.thickness != thickness ||
        old.progressExtraThickness != progressExtraThickness ||
        old.trackColor != trackColor ||
        old.baseColor != baseColor ||
        old.gradientColors != gradientColors ||
        old.gradientStops != gradientStops;
  }
}

