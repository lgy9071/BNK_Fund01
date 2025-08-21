import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FundMbtiFlowScreen extends StatefulWidget {
  const FundMbtiFlowScreen({super.key});
  @override
  State<FundMbtiFlowScreen> createState() => _FundMbtiFlowScreenState();
}

// 토스 파스텔 배경
const tossBlue = Color(0xFF0064FF);
final Color tossPastel = Color.lerp(Colors.white, tossBlue, 0.12)!;

enum _Stage { clouds, panel, quiz, result }

class _FundMbtiFlowScreenState extends State<FundMbtiFlowScreen>
    with TickerProviderStateMixin {
  _Stage _stage = _Stage.clouds;

  // MBTI 풍선 애니메이션 (M→B→T→I 순차 팝)
  late final AnimationController _lettersCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  // 퀴즈 상태
  int _idx = -1; // -1이면 퀴즈 전
  final List<int?> _answers = List<int?>.filled(5, null);

  // 질문 데이터 (bg는 유지하지만 화면 배경에는 사용하지 않음)
  final _questions = const [
    _Q(
      text: '1. 투자 시 더 중요한 것은?',
      a: '무조건!!\n높은 수익률',
      b: '조금 천천히 오르더라도\n안전하게!!',
      bg: Color(0xFFE4D6FF),
      imgA: 'assets/images/1-1.png',
      imgB: 'assets/images/1-3.png',
    ),
    _Q(
      text: '2. 투자를 시작할 때',
      a: '계획을 철저히 세운 뒤\n신중히 시작',
      b: '일단 시작하고\n경험하면서 배우는 편',
      bg: Color(0xFFE4D6FF),
      imgA: 'assets/images/2-3.png',
      imgB: 'assets/images/icons6.png',
    ),
    _Q(
      text: '3. 펀드 가입 직전에 당신은?',
      a: '마지막까지 혼자 비교\n분석하고 신중히 고민',
      b: '경험 있는 지인의 의견을\n들어보며 결정',
      bg: Color(0xFFE4D6FF),
      imgA: 'assets/images/2-4.png',
      imgB: 'assets/images/3-1.png',
    ),
    _Q(
      text: '4. 펀드 수익률이 5% 하락했다면?',
      a: '더 떨어지기 전에\n빨리 팔자!!',
      b: '다시 오를테니까\n기다려보자~',
      bg: Color(0xFFE4D6FF),
      imgA: 'assets/images/4-2.png',
      imgB: 'assets/images/4-5.png',
    ),
    _Q(
      text: '5. 투자 중 수익이 크게 오르면??',
      a: '지금이 기회야!\n수익 실현!',
      b: '아직 목표 안 됐어.\n더 기다려~',
      bg: Color(0xFFE4D6FF),
      imgA: 'assets/images/5-1.png',
      imgB: 'assets/images/5-2.png',
    ),
  ];

  // 결과 매핑(샘플)
  final Map<String, _Result> _resultMap = const {
    'AGG-PLAN-ANA-REACT-HIGH': _Result(
      title: '분석공격형',
      desc: '계획/분석력을 바탕으로 적극적인 수익을 추구합니다.',
      tag: '#분석 #공격적투자',
    ),
    'AGG-PLAN-ANA-PATI-STEAD': _Result(
      title: '경제분석형',
      desc: '데이터 기반으로 장기적 안목을 지닌 투자자입니다.',
      tag: '#분석적장기투자자',
    ),
    'SAFE-PLAN-ANA-PATI-STEAD': _Result(
      title: '안정분석형',
      desc: '분석 기반의 안정형 투자자입니다.',
      tag: '#분석형 #신중한',
    ),
    'SAFE-PLAN-TREND-REACT-HIGH': _Result(
      title: '민첩수익형',
      desc: '빠르게 시장에 반응하며 고수익을 노립니다.',
      tag: '#신중하지만 #스피디',
    ),
    'AGG-FREE-TREND-REACT-HIGH': _Result(
      title: '즉흥공격형',
      desc: '감각과 속도로 움직이는 민첩한 고위험 투자자입니다.',
      tag: '#스피드투자 #고수익고위험',
    ),
  };

  late _Result _result;

  @override
  void initState() {
    super.initState();
    // 인트로가 끝나면 자동으로 시작 패널로
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _stage = _Stage.panel);
    });
  }

  @override
  void dispose() {
    _lettersCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _buildStage(),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _Stage.clouds:
        return _CloudsIntro(
          lettersCtl: _lettersCtl,
          onSkip: () => setState(() => _stage = _Stage.panel),
        );
      case _Stage.panel:
        return _StartPanel(
          onStart: () {
            HapticFeedback.selectionClick();
            setState(() {
              _stage = _Stage.quiz;
              _idx = 0;
            });
          },
        );
      case _Stage.quiz:
        final q = _questions[_idx];
        return _QuestionScene(
          key: ValueKey(_idx),
          q: q,
          index: _idx,
          total: _questions.length,
          onPick: (choice) async {
            HapticFeedback.lightImpact();
            _answers[_idx] = choice;
            if (_idx == _questions.length - 1) {
              final res = _resultMap[_buildCode()] ?? _fallbackByScore();
              setState(() {
                _result = res;
                _stage = _Stage.result;
              });
            } else {
              setState(() => _idx++);
            }
          },
          onPrev: _idx == 0
              ? null
              : () => setState(() => _idx--),
        );
      case _Stage.result:
        return _ResultPage(
          result: _result,
          onRestart: () {
            setState(() {
              _answers.fillRange(0, _answers.length, null);
              _idx = -1;
              _stage = _Stage.clouds;
              _lettersCtl
                ..reset()
                ..forward();
            });
            Future.delayed(const Duration(milliseconds: 2600), () {
              if (!mounted) return;
              setState(() => _stage = _Stage.panel);
            });
          },
        );
    }
  }

  String _buildCode() {
    final aggr = _answers[0] == 0 ? 'AGG' : 'SAFE';
    final planning = _answers[1] == 0 ? 'PLAN' : 'FREE';
    final info = _answers[2] == 0 ? 'ANA' : 'TREND';
    final response = _answers[3] == 1 ? 'PATI' : 'REACT';
    final goal = _answers[4] == 1 ? 'STEAD' : 'HIGH';
    return '$aggr-$planning-$info-$response-$goal';
  }

  _Result _fallbackByScore() {
    int score = 0;
    for (final a in _answers) {
      if ((a ?? 0) == 0) score++;
    }
    if (score <= 1) {
      return const _Result(title: '안정형', desc: '원금손실에 매우 민감한 보수적 성향.', tag: '#안정');
    } else if (score == 2) {
      return const _Result(title: '안정추구형', desc: '낮은 위험을 선호하며 수익은 보조.', tag: '#안정추구');
    } else if (score == 3) {
      return const _Result(title: '위험중립형', desc: '수익/위험의 균형을 중시.', tag: '#중립');
    } else if (score == 4) {
      return const _Result(title: '적극투자형', desc: '평균 이상 수익을 위해 위험 감내.', tag: '#적극');
    }
    return const _Result(title: '공격투자형', desc: '높은 변동성과 손실 가능성을 감내.', tag: '#공격');
  }
}

/* ───────── [Scene 1] 구름 + MBTI 풍선 ───────── */

class _CloudsIntro extends StatefulWidget {
  final AnimationController lettersCtl;
  final VoidCallback onSkip;
  const _CloudsIntro({required this.lettersCtl, required this.onSkip});

  @override
  State<_CloudsIntro> createState() => _CloudsIntroState();
}

class _CloudsIntroState extends State<_CloudsIntro> {
  bool _in = false;

  Animation<double> _pop(int order) {
    final start = 0.05 + order * .18;
    final end = start + .24;
    return CurvedAnimation(
      parent: widget.lettersCtl,
      curve: Interval(start, end, curve: Curves.elasticOut),
    );
  }

  @override
  void initState() {
    super.initState();
    // 구름을 화면 밖에서 안쪽으로
    Future.microtask(() => setState(() => _in = true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tossPastel, // ✅ 토스 파스텔
      body: SafeArea(
        child: Stack(
          children: [
            // Left cloud
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              left: _in ? -12 : -180,
              bottom: 18,
              child: const _CloudShape(width: 180, height: 100),
            ),
            // Right cloud
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              right: _in ? -12 : -180,
              bottom: 22,
              child: const _CloudShape(width: 180, height: 100),
            ),

            // Center “MBTI” balloons (pop-in)
            Align(
              alignment: const Alignment(0, -0.05),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BalloonPop('assets/images/balloon_M.png', _pop(0)),
                  const SizedBox(width: 8),
                  _BalloonPop('assets/images/balloon_B2.png', _pop(1)),
                  const SizedBox(width: 8),
                  _BalloonPop('assets/images/balloon_T.png', _pop(2)),
                  const SizedBox(width: 8),
                  _BalloonPop('assets/images/balloon_I.png', _pop(3)),
                ],
              ),
            ),

            Positioned(
              right: 8,
              top: 8,
              child: TextButton(onPressed: widget.onSkip, child: const Text('건너뛰기')),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalloonPop extends StatelessWidget {
  final String asset;
  final Animation<double> anim;
  const _BalloonPop(this.asset, this.anim, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.0, end: 1.0).animate(anim),
      child: FadeTransition(
        opacity: anim,
        child: Image.asset(asset, width: 56, height: 56, fit: BoxFit.contain),
      ),
    );
  }
}

class _CloudShape extends StatelessWidget {
  final double width, height;
  const _CloudShape({required this.width, required this.height, super.key});

  @override
  Widget build(BuildContext context) {
    // 겹친 원 3개로 만든 간단한 구름
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: width * .1, bottom: 0, child: _b(width * .55)),
          Positioned(left: -8, bottom: height * .12, child: _b(width * .42)),
          Positioned(right: -6, bottom: height * .18, child: _b(width * .48)),
        ],
      ),
    );
  }

  Widget _b(double s) => Container(
    width: s,
    height: s,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
    ),
  );
}

/* ───────── [Scene 2] 시작 패널 ───────── */

class _StartPanel extends StatefulWidget {
  final VoidCallback onStart;
  const _StartPanel({required this.onStart});

  @override
  State<_StartPanel> createState() => _StartPanelState();
}

class _StartPanelState extends State<_StartPanel> {
  bool _in = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 30), () {
      if (mounted) setState(() => _in = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tossPastel, // ✅ 토스 파스텔
      body: SafeArea(
        child: Center(
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            offset: _in ? Offset.zero : const Offset(0, .2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: _in ? 1 : 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 본체
                  Container(
                    width: 320,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF9B6BFF), width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 14,
                          offset: Offset(8, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 상단 라벨 바
                        Container(
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF9B6BFF), width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Text('펀드 MBTI',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: Color(0xFF9B6BFF))),
                        ),
                        const SizedBox(height: 10),

                        // 안쪽 화면
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B63E9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF4D40B8), width: 2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('나의 투자 유형 테스트',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  _LetterTile('M'),
                                  SizedBox(width: 8),
                                  _LetterTile('B'),
                                  SizedBox(width: 8),
                                  _LetterTile('T'),
                                  SizedBox(width: 8),
                                  _LetterTile('I'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF3D9A),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: widget.onStart,
                                child: const Text('시작하기'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 하단 점 + 슬롯
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 3; i++)
                              Container(
                                width: 10,
                                height: 10,
                                margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE4D6FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8DFFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 오른쪽 손잡이
                  Positioned(
                    right: -14,
                    top: 56,
                    child: Container(
                      width: 22,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B6BFF),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(2, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  final String ch;
  const _LetterTile(this.ch, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFFFF59D),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFD2B8FF), width: 2),
    ),
    child: Text(
      ch,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFFFF3D9A),
        shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
      ),
    ),
  );
}

/* ───────── [Scene 3] 질문 ───────── */

class _QuestionScene extends StatefulWidget {
  final _Q q;
  final int index, total;
  final ValueChanged<int> onPick;
  final VoidCallback? onPrev;
  const _QuestionScene({
    super.key,
    required this.q,
    required this.index,
    required this.total,
    required this.onPick,
    this.onPrev,
  });

  @override
  State<_QuestionScene> createState() => _QuestionSceneState();
}

class _QuestionSceneState extends State<_QuestionScene> {
  bool _slideOut = false;

  Future<void> _choose(int v) async {
    setState(() => _slideOut = true); // ← 흰 카드 왼쪽으로 이탈
    await Future.delayed(const Duration(milliseconds: 260));
    widget.onPick(v);                  // 다음 문항(오른쪽에서 인)
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    return Scaffold(
      backgroundColor: tossPastel,
      body: SafeArea(
        child: Stack(
          children: [
            // 진행도
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: LinearProgressIndicator(
                value: (widget.index + 1) / widget.total,
                backgroundColor: Colors.white.withOpacity(.35),
                valueColor: const AlwaysStoppedAnimation<Color>(tossBlue),
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // 본문 카드
            Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInCubic,
                offset: _slideOut ? const Offset(-1.1, 0) : Offset.zero,
                child: _QuestionCard(
                  q: q,
                  index: widget.index,
                  total: widget.total,
                  onPick: _choose,
                  onPrev: widget.onPrev,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final _Q q;
  final int index, total;
  final ValueChanged<int> onPick;
  final VoidCallback? onPrev;

  const _QuestionCard({
    super.key,
    required this.q,
    required this.index,
    required this.total,
    required this.onPick,
    this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(q.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OptionCard(label: q.a, imgAsset: q.imgA, delayMs: 40, onTap: () => onPick(0)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OptionCard(label: q.b, imgAsset: q.imgB, delayMs: 140, onTap: () => onPick(1)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onPrev != null)
                TextButton.icon(
                  onPressed: onPrev,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('이전으로'),
                ),
              const Spacer(),
              Text('${index + 1} / $total'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String label;
  final String? imgAsset;
  final VoidCallback onTap;
  final int delayMs;
  const _OptionCard({
    required this.label,
    required this.onTap,
    this.imgAsset,
    this.delayMs = 0,
    super.key,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _in = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _in = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      offset: _in ? Offset.zero : const Offset(0, .15),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 360),
        opacity: _in ? 1 : 0,
        child: Material(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.imgAsset != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Image.asset(
                        widget.imgAsset!,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ───────── [Scene 4] 결과 ───────── */

class _ResultPage extends StatelessWidget {
  final _Result result;
  final VoidCallback onRestart;
  const _ResultPage({required this.result, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tossPastel, // ✅ 토스 파스텔
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '나의 투자 MBTI는?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF383E56),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14)],
                    ),
                    child: Column(
                      children: [
                        Text(
                          result.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          result.desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, color: Color(0xFF49506A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    result.tag,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7B7F8C),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Image.asset(
                    'assets/images/mbti-char3.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('투자성향 분석하러 가기', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: onRestart, child: const Text('테스트 다시하기')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ───────── 데이터 타입 ───────── */

class _Q {
  final String text, a, b;
  final Color bg;
  final String? imgA, imgB;
  const _Q({
    required this.text,
    required this.a,
    required this.b,
    required this.bg,
    this.imgA,
    this.imgB,
  });
}

class _Result {
  final String title, desc, tag;
  const _Result({required this.title, required this.desc, required this.tag});
}
