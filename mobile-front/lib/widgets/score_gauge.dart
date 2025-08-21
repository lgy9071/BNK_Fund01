import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class ScoreGauge extends StatefulWidget {
  final int score;
  final int maxScore;
  final Color color;
  final double size; // 요청한 기준 너비(부모 폭이 더 작으면 자동 축소)
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
    final rawPercent = (widget.score / widget.maxScore).clamp(0.0, 1.0);
    final pct100 = (rawPercent * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 부모 제약 내에서 결국 사용할 실제 너비/높이
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : widget.size;
        final effW = math.min(widget.size, maxW); // 실제 사용 너비
        final effH = effW * 0.66;                 // 반원 게이지 높이 비율

        // 비율 기반 여백/폰트 사이즈 (클램프로 과도한 축소/확대 방지)
        double clamp(double v, double min, double max) => math.max(min, math.min(max, v));
        final topGap  = clamp(effH * 0.26, 14, 72);   // 상단 여백
        final midGap  = clamp(effH * 0.08,  8, 28);   // 점수와 라벨 사이
        final fsMain  = clamp(effW * 0.18, 22, 56);   // 큰 숫자
        final fsSub   = clamp(effW * 0.065,10, 22);   // "/ 100"
        final fsLabel = clamp(effW * 0.06, 10, 20);   // "위험도 점수"

        return AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final p = rawPercent * _anim.value;
            return SizedBox(
              width: effW,
              height: effH,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 게이지
                  CustomPaint(
                    size: Size(effW, effH),
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

                  // 중앙 텍스트
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: topGap),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$pct100',
                                style: TextStyle(
                                  fontSize: fsMain,
                                  height: 1.0,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.fontColor,
                                ),
                              ),
                              TextSpan(
                                text: ' / 100',
                                style: TextStyle(
                                  fontSize: fsSub,
                                  height: 1.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.fontColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: midGap),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '위험도 점수',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: fsLabel,
                            color: AppColors.fontColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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

    final diameter = size.width - progressStroke;
    final rect = Rect.fromLTWH(
      progressStroke / 2,
      progressStroke / 2,
      diameter,
      diameter,
    );
    final r = rect.width / 2;

    const startAngle = math.pi;   // 9시
    const fullSweep  = math.pi;   // 반원

    final trackPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackStroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, startAngle, fullSweep, false, trackPaint);

    final gradPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressStroke
      ..strokeCap = StrokeCap.butt;

    final capPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressStroke
      ..strokeCap = StrokeCap.round;

    List<Color> colors;
    List<double> stops;
    if (gradientColors != null && gradientColors!.isNotEmpty) {
      colors = List<Color>.from(gradientColors!);
      stops  = (gradientStops != null && gradientStops!.length == colors.length)
          ? List<double>.from(gradientStops!)
          : _autoStops(colors.length);

      gradPaint.shader = SweepGradient(
        startAngle: math.pi,
        endAngle: 2 * math.pi,
        colors: [...colors, colors.last],
        stops:  [...stops,  1.0],
        tileMode: TileMode.clamp,
      ).createShader(rect);
    } else {
      colors = [baseColor, baseColor];
      stops  = const [0.0, 1.0];
      gradPaint.color = baseColor;
    }

    final p = progress.clamp(0.0, 1.0);
    final sweep = fullSweep * p;
    if (sweep <= 0) return;

    // 본체(그라데이션)
    canvas.drawArc(rect, startAngle, sweep, false, gradPaint);

    // 라운드 캡(양끝): 짧은 호로 색 맞춰서 그리기
    final capAngle = (progressStroke / 2) / r;
    final tiny = math.min(sweep / 2, capAngle * 0.05);

    if (tiny > 0) {
      final tStart = (tiny / 2) / fullSweep;
      final tEnd   = (sweep - tiny / 2) / fullSweep;
      final startColor = _sampleColor(colors, stops, tStart);
      final endColor   = _sampleColor(colors, stops, tEnd);

      capPaint.color = startColor;
      canvas.drawArc(rect, startAngle, tiny, false, capPaint);

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
