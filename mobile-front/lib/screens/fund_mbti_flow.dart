import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 배경/스타일
const _bg = Color(0xFFF1E8FF);
const _ink = Color(0xFF2A2C3B);
const _card = Colors.white;
Color _pastel(Color c, [double t = .86]) => Color.lerp(c, Colors.white, t)!;

/// ===== 질문 데이터 (웹과 동일) =====
class MbtiQ {
  final String text;
  final List<String> options; // 길이 2
  final Color color;
  final String charAsset;     // 캐릭터 이미지
  const MbtiQ({required this.text, required this.options, required this.color, required this.charAsset});
}

const List<MbtiQ> kMbtiQuestions = [
  MbtiQ(
    text: '1. 투자 시 더 중요한 것은?',
    options: ['수익률', '안정성'],
    color: Color(0xFF00D290),
    charAsset: 'assets/images/mbti3.png',
  ),
  MbtiQ(
    text: '2. 투자를 시작할 때',
    options: ['계획을 철저히 세운 뒤 \n신중히 시작', '일단 시작하고 \n경험하면서 배우는 편'],
    color: Color(0xFF00CBD2),
    charAsset: 'assets/images/icons6.png',
  ),
  MbtiQ(
    text: '3. 투자 정보를 얻을 때',
    options: ['뉴스, 리포트', 'SNS, 커뮤니티'],
    color: Color(0xFF9AD200),
    charAsset: 'assets/images/icons3.png',
  ),
  MbtiQ(
    text: '4. 펀드 수익률이 5% 하락했다면?',
    options: ['바로 환매', '더 기다림'],
    color: Color(0xFFFF2776),
    charAsset: 'assets/images/icons11.png',
  ),
  MbtiQ(
    text: '5. 펀드 상품을 고를 때 기준은?',
    options: ['높은 수익률', '꾸준한 수익'],
    color: Color(0xFFFF9D23),
    charAsset: 'assets/images/icons8.png',
  ),
];

/// ===== 결과 모델/맵 (웹 resultMap 그대로 포팅) =====
class MbtiResult {
  final String title;
  final String description;
  final String tag;
  final String imageAsset;
  const MbtiResult(this.title, this.description, this.tag, this.imageAsset);
}

final Map<String, MbtiResult> _resultMap = {
  "AGG-PLAN-ANA-PATI-STEAD": MbtiResult("경제분석형",
      "시장과 데이터를 기반으로 장기적 안목을 지닌 투자자입니다.", "#분석적장기투자자", "assets/images/mbti_char2.jpg"),
  "AGG-PLAN-ANA-PATI-HIGH": MbtiResult("수익추구형",
      "분석과 전략을 바탕으로 고수익을 추구하는 투자자입니다.", "#전략가 #고수익", "assets/images/mbti_char2.jpg"),
  "AGG-PLAN-ANA-REACT-STEAD": MbtiResult("신중대응형",
      "계획적으로 분석하지만 빠르게 반응할 줄 아는 투자자입니다.", "#계획형 #기민한", "assets/images/mbti_char2.jpg"),
  "AGG-PLAN-ANA-REACT-HIGH": MbtiResult("분석공격형",
      "계획과 분석력을 바탕으로 적극적인 수익을 추구합니다.", "#분석 #공격적투자", "assets/images/mbti_char2.jpg"),
  "AGG-PLAN-TREND-PATI-STEAD": MbtiResult("트렌드분석형",
      "시장 트렌드를 따르면서도 장기적인 성향을 유지합니다.", "#트렌드분석 #장기투자", "assets/images/mbti_char2.jpg"),
  "AGG-PLAN-TREND-PATI-HIGH": MbtiResult("고수익트렌더",
      "시장 흐름에 민감하며 고수익 기회를 노리는 투자자입니다.", "#트렌드 #수익형", "assets/images/mbti_char2.jpg"),
  "AGG-PLAN-TREND-REACT-STEAD": MbtiResult("트렌드중시형",
      "시장 흐름에 민감하게 반응하는 반응형 투자자입니다.", "#트렌드헌터", "assets/images/mbti_char2.jpg"),
  "AGG-PLAN-TREND-REACT-HIGH": MbtiResult("공격형트렌더",
      "변화에 즉각 대응하며 수익 극대화를 추구합니다.", "#즉응형 #공격투자자", "assets/images/mbti_char2.jpg"),
  "AGG-FREE-ANA-PATI-STEAD": MbtiResult("직관분석형",
      "자유롭게 접근하되 분석 기반으로 안정성을 추구합니다.", "#직관적 #분석형", "assets/images/mbti_char2.jpg"),
  "AGG-FREE-ANA-PATI-HIGH": MbtiResult("자유수익형",
      "분석보다는 직감과 수익성에 초점을 둔 투자자입니다.", "#자유형 #고수익지향", "assets/images/mbti_char2.jpg"),
  "AGG-FREE-ANA-REACT-STEAD": MbtiResult("직관대응형",
      "분석보다 반응에 강하며 균형 감각이 뛰어난 투자자입니다.", "#기민형 #직관형", "assets/images/mbti_char2.jpg"),
  "AGG-FREE-ANA-REACT-HIGH": MbtiResult("공격직관형",
      "감각적으로 움직이며 빠른 판단으로 수익을 추구합니다.", "#감투자 #스피드형", "assets/images/mbti_char2.jpg"),
  "AGG-FREE-TREND-PATI-STEAD": MbtiResult("트렌드감성형",
      "시장 감각에 민감하며 장기적 안정도 고려합니다.", "#감성형 #트렌디", "assets/images/mbti_char2.jpg"),
  "AGG-FREE-TREND-PATI-HIGH": MbtiResult("감성수익형",
      "트렌드를 타고 고수익을 노리는 감각적 투자자입니다.", "#감각형 #고위험", "assets/images/mbti_char2.jpg"),
  "AGG-FREE-TREND-REACT-STEAD": MbtiResult("트렌드직감형",
      "직관적이며 트렌드에 즉각 반응하는 균형잡힌 투자자입니다.", "#트렌디 #중립형", "assets/images/mbti_char2.jpg"),
  "AGG-FREE-TREND-REACT-HIGH": MbtiResult("즉흥공격형",
      "감각과 속도로 움직이는 민첩한 고위험 투자자입니다.", "#스피드투자 #고위험고수익", "assets/images/mbti_char2.jpg"),
  "SAFE-PLAN-ANA-PATI-STEAD": MbtiResult("안정분석형",
      "분석 기반의 안정형 투자자입니다.", "#분석형 #신중한", "assets/images/mbti_char2.jpg"),
  "SAFE-PLAN-ANA-PATI-HIGH": MbtiResult("신중수익형",
      "분석 기반이지만 수익도 포기하지 않는 안정추구 투자자입니다.", "#신중 #수익추구", "assets/images/mbti_char2.jpg"),
  "SAFE-PLAN-ANA-REACT-STEAD": MbtiResult("보수대응형",
      "계획적으로 분석하면서도 빠르게 반응할 수 있는 투자자입니다.", "#보수적 #기민한", "assets/images/mbti_char2.jpg"),
  "SAFE-PLAN-ANA-REACT-HIGH": MbtiResult("조심공격형",
      "신중하지만 필요한 순간에는 공격적으로 움직일 수 있습니다.", "#신중공격형", "assets/images/mbti_char2.jpg"),
  "SAFE-PLAN-TREND-PATI-STEAD": MbtiResult("안정트렌더",
      "트렌드를 관찰하면서도 안정적인 접근을 선호합니다.", "#트렌드 #안정형", "assets/images/mbti_char2.jpg"),
  "SAFE-PLAN-TREND-PATI-HIGH": MbtiResult("트렌드수익형",
      "시장 흐름을 기반으로 수익을 추구하는 균형형 투자자입니다.", "#트렌디 #수익형", "assets/images/mbti_char2.jpg"),
  "SAFE-PLAN-TREND-REACT-STEAD": MbtiResult("보수트렌더",
      "트렌드를 민감하게 따르지만 안정성을 중요시합니다.", "#트렌디 #안정추구", "assets/images/mbti_char2.jpg"),
  "SAFE-PLAN-TREND-REACT-HIGH": MbtiResult("민첩수익형",
      "빠르게 시장에 반응하며 고수익을 노리는 조심스러운 투자자입니다.", "#신중하지만 #스피디", "assets/images/mbti_char2.jpg"),
  "SAFE-FREE-ANA-PATI-STEAD": MbtiResult("자유분석형",
      "분석은 철저히 하지만 자유롭게 투자하는 스타일입니다.", "#자유형 #분석중시", "assets/images/mbti_char2.jpg"),
  "SAFE-FREE-ANA-PATI-HIGH": MbtiResult("분석수익형",
      "분석을 바탕으로 고수익 상품을 찾는 자유로운 투자자입니다.", "#분석기반 #수익형", "assets/images/mbti_char2.jpg"),
  "SAFE-FREE-ANA-REACT-STEAD": MbtiResult("즉응형분석가",
      "상황에 따라 움직이지만 기반은 분석입니다.", "#반응형 #분석중심", "assets/images/mbti_char2.jpg"),
  "SAFE-FREE-ANA-REACT-HIGH": MbtiResult("공격분석형",
      "공격적으로 움직이지만 분석은 놓치지 않는 투자자입니다.", "#공격 #분석기반", "assets/images/mbti_char2.jpg"),
  "SAFE-FREE-TREND-PATI-STEAD": MbtiResult("감각안정형",
      "트렌드를 살피되 안정적인 상품 위주로 구성합니다.", "#감성형 #안정지향", "assets/images/mbti_char2.jpg"),
  "SAFE-FREE-TREND-PATI-HIGH": MbtiResult("감성수익형",
      "트렌드와 감을 바탕으로 수익을 노리는 투자자입니다.", "#감각 #수익형", "assets/images/mbti_char2.jpg"),
  "SAFE-FREE-TREND-REACT-STEAD": MbtiResult("민첩안정형",
      "빠른 반응을 하되, 안정적인 방향으로 유지합니다.", "#신중기민 #안정중심", "assets/images/mbti_char2.jpg"),
  "SAFE-FREE-TREND-REACT-HIGH": MbtiResult("즉흥형감성투자자",
      "감각적으로 반응하며 수익을 노리는 투자자입니다.", "#감각형 #고수익 #유연함", "assets/images/mbti_char2.jpg"),
};

MbtiResult _fallback(String code) => MbtiResult(
  "균형형",
  "제시된 조합에 대한 설명이 없어 기본 유형으로 안내드려요. (code: $code)",
  "#중립 #테스트",
  "assets/images/mbti_char2.jpg",
);

/// ===== 플로우 =====
class FundMbtiFlowScreen extends StatefulWidget {
  const FundMbtiFlowScreen({super.key});
  @override
  State<FundMbtiFlowScreen> createState() => _FundMbtiFlowScreenState();
}

class _FundMbtiFlowScreenState extends State<FundMbtiFlowScreen> {
  final _page = PageController();
  int _idx = 0;
  // 각 문항의 선택 인덱스(0/1)
  final List<int?> _answers = List<int?>.filled(kMbtiQuestions.length, null);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.selectionClick();
    _go(1);
  }

  void _go(int p) {
    setState(() => _idx = p);
    _page.animateToPage(p, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  void _choose(int qIndex, int optIndex) async {
    HapticFeedback.lightImpact();
    _answers[qIndex] = optIndex;

    if (qIndex == kMbtiQuestions.length - 1) {
      final code = _buildCode(_answers.cast<int>());
      final res = _resultMap[code] ?? _fallback(code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _MbtiResultScreen(result: res)),
      );
      return;
    }
    await Future.delayed(const Duration(milliseconds: 120));
    _go(_idx + 1);
  }

  /// 웹 showResult와 동일한 규칙(문항별 코드 파트)
  String _buildCode(List<int> answers) {
    // 0: 수익률(AGG) vs 안정성(SAFE)
    final a = answers[0] == 0 ? "AGG" : "SAFE";
    // 1: 계획(PLAN) vs 자유(FREE)  ※ option[0]이 PLAN
    final b = answers[1] == 0 ? "PLAN" : "FREE";
    // 2: 뉴스/리포트(ANA) vs SNS/커뮤니티(TREND)  ※ option[0]이 ANA
    final c = answers[2] == 0 ? "ANA" : "TREND";
    // 3: 바로 환매(REACT) vs 더 기다림(PATI)  ※ option[1]이 PATI
    final d = answers[3] == 1 ? "PATI" : "REACT";
    // 4: 높은 수익률(HIGH) vs 꾸준한 수익(STEAD)  ※ option[1]이 STEAD
    final e = answers[4] == 1 ? "STEAD" : "HIGH";
    return "$a-$b-$c-$d-$e";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: PageView(
          controller: _page,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _Intro(onStart: _start),
            for (int i = 0; i < kMbtiQuestions.length; i++)
              _QuestionPage(
                qIndex: i,
                q: kMbtiQuestions[i],
                progress: '${i + 1}/${kMbtiQuestions.length} (${((i + 1) / kMbtiQuestions.length * 100).round()}%)',
                onBack: i == 0 ? null : () => _go(_idx - 1),
                onChooseLeft: () => _choose(i, 0),
                onChooseRight: () => _choose(i, 1),
              ),
          ],
        ),
      ),
    );
  }
}

/// ===== 인트로 =====
class _Intro extends StatefulWidget {
  final VoidCallback onStart;
  const _Intro({required this.onStart});
  @override
  State<_Intro> createState() => _IntroState();
}

class _IntroState extends State<_Intro> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }
  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _ac,
          builder: (_, __) {
            final t = _ac.value;
            return Stack(children: [
              _cloud(left: -60 + 40 * math.sin(t * math.pi * 2), bottom: 80),
              _cloud(right: -50 + 50 * math.cos(t * math.pi * 2), top: 120),
            ]);
          },
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Bubble('MBTI'),
              const SizedBox(height: 10),
              const Text('나의 투자 성격은?', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFF7A5CFF),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: widget.onStart,
                child: const Text('테스트 시작', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cloud({double? left, double? right, double? top, double? bottom}) {
    return Positioned(
      left: left, right: right, top: top, bottom: bottom,
      child: Container(width: 120, height: 60,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(40))),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String t;
  const _Bubble(this.t);
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        colors: [Color(0xFFFF5FA2), Color(0xFF7A5CFF)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(r),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 68, fontWeight: FontWeight.w900, height: .9, color: Colors.white,
          shadows: [Shadow(color: Colors.black.withOpacity(.2), blurRadius: 16, offset: const Offset(0, 6))],
        ),
      ),
    );
  }
}

/// ===== 질문 =====
class _QuestionPage extends StatelessWidget {
  final int qIndex;
  final MbtiQ q;
  final String progress;
  final VoidCallback? onBack;
  final VoidCallback onChooseLeft, onChooseRight;

  const _QuestionPage({
    required this.qIndex,
    required this.q,
    required this.progress,
    required this.onChooseLeft,
    required this.onChooseRight,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final accent = q.color;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('펀드 MBTI', style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: onBack == null ? const SizedBox() :
        IconButton(icon: const Icon(Icons.chevron_left, color: _ink), onPressed: onBack),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _Progress(step: qIndex + 1, total: kMbtiQuestions.length, label: progress, color: accent),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 90,
                        child: Image.asset(q.charAsset, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(Icons.image, color: accent, size: 40)),
                      ),
                      const SizedBox(height: 8),
                      Text(q.text, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _Option(text: q.options[0], accent: accent, onTap: onChooseLeft)),
                          const SizedBox(width: 12),
                          Expanded(child: _Option(text: q.options[1], accent: accent, onTap: onChooseRight, right: true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(qIndex == 0 ? '' : '이전으로', style: TextStyle(color: _ink.withOpacity(.6))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatefulWidget {
  final String text; final VoidCallback onTap; final bool right; final Color accent;
  const _Option({required this.text, required this.onTap, required this.accent, this.right = false});
  @override State<_Option> createState() => _OptionState();
}
class _OptionState extends State<_Option> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final bg = _pastel(widget.accent, widget.right ? .90 : .85);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100), scale: _down ? .98 : 1,
        child: Container(
          height: 150, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.accent.withOpacity(.22), width: 1.2),
          ),
          child: Center(
            child: Text(widget.text, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int step, total; final String label; final Color color;
  const _Progress({required this.step, required this.total, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    final ratio = step / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(children: [
            Container(height: 10, color: Colors.white.withOpacity(.7)),
            AnimatedContainer(duration: const Duration(milliseconds: 300),
                height: 10, width: MediaQuery.of(context).size.width * ratio, color: color),
          ]),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: _ink.withOpacity(.7), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// ===== 결과 =====
class _MbtiResultScreen extends StatelessWidget {
  final MbtiResult result;
  const _MbtiResultScreen({super.key, required this.result});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: _bg, elevation: 0, title: const Text('Result', style: TextStyle(color: _ink)), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  color: _card, borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: Column(children: [
                  const SizedBox(height: 6),
                  const Text('나의 투자 MBTI는 ?', style: TextStyle(fontSize: 16, color: _ink, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(result.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _ink)),
                  const SizedBox(height: 10),
                  Text(result.description, textAlign: TextAlign.center, style: TextStyle(color: _ink.withOpacity(.8))),
                  const SizedBox(height: 14),
                  Container(
                    height: 160, width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FFF6), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF82D9A1).withOpacity(.35)),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(result.imageAsset, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text('🐣 캐릭터/일러스트 영역')),
                  ),
                  const Spacer(),
                  Text(result.tag, style: TextStyle(color: _ink.withOpacity(.55), fontSize: 12)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF7A5CFF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: const Color(0xFF7A5CFF),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => const FundMbtiFlowScreen())),
                  child: const Text('테스트 다시하기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF7A5CFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pushNamed('/invest-type'),
                  child: const Text('투자성향 분석하러 가기'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }
}