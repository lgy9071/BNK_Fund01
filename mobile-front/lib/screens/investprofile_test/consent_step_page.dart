import 'package:flutter/material.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/screens/investprofile_test/questionnaire_screen.dart';
import 'package:mobile_front/widgets/step_header.dart';
import 'package:mobile_front/core/constants/colors.dart'; // AppColors.primaryBlue

/// 작성동의 (큰 단계 1/3)
/// - onNext: 동의 저장 성공 후 문제 화면으로 넘어갈 때 호출
/// - onSubmit: (선택) 서버에 동의 저장할 때 사용. 없으면 바로 onNext만 호출.

class ConsentStepPage extends StatefulWidget {
  final VoidCallback onNext;
  final Future<void> Function(bool agreed)? onSubmit;

  const ConsentStepPage({
    super.key,
    required this.onNext,
    this.onSubmit,
  });

  @override
  State<ConsentStepPage> createState() => _ConsentStepPageState();
}

class _ConsentStepPageState extends State<ConsentStepPage> {
  bool agreeInvestorInfo = false; // (필수) 안 읽어도 체크 가능
  bool expandInvestorInfo = false; // 아코디언 펼침 상태
  bool submitting = false;

  Future<void> _handleNext() async {
    if (!agreeInvestorInfo || submitting) return;
    setState(() => submitting = true);
    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(agreeInvestorInfo);
      }
      if (!mounted) return;
      widget.onNext();
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ✅ 두 타이틀 통일 스타일
    final titleStyleUnified = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('작성 동의'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          const StepHeader(bigStep: 1, showBigProgress: false),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                const SizedBox(height: 20),
                _InfoCard(
                  title: '투자성향분석',
                  bullets: const [
                    '고객님은 자본시장통합법 시행세칙에 의거 일반고객으로 \n분류되었음을 알려드립니다.',
                    '고객님의 투자 성향을 파악하여 적합한 상품 권유를 위한 \n기초 자료로 활용됩니다.',
                  ],
                  titleStyle: titleStyleUnified,
                ),
                const SizedBox(height: 12),
                _AccordionConsentCard(
                  title: '투자자정보확인서 작성 동의 (필수)',
                  sub_title: '투자자 정보를 제공하지 않는 고객님께서는 다음의 금융투자상품에 대한 투자권유 및 일반투자자로서 보호받지 못할 수 있음을 \n알려드립니다.',
                  expanded: expandInvestorInfo,
                  onToggle: () => setState(() => expandInvestorInfo = !expandInvestorInfo),
                  body: const _AccordionBody(),
                  titleStyle: titleStyleUnified,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: agreeInvestorInfo,
                      onChanged: (val) {
                        setState(() => agreeInvestorInfo = val ?? false);
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() => agreeInvestorInfo = !agreeInvestorInfo);
                      },
                      child: Text(
                        '투자자정보확인서 작성 동의',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (agreeInvestorInfo && !submitting)
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    foregroundColor: (agreeInvestorInfo && !submitting)
                        ? Colors.white
                        : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: (agreeInvestorInfo && !submitting)
                      ? () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
                    );

                    if (result != null) {
                      debugPrint('설문 결과: $result');
                    }
                  }
                      : null,
                  child: const Text('다음', style: TextStyle(fontSize: 17),),
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }
}

/* ----------------------------- 내부 위젯들 ----------------------------- */

/// 항상 펼쳐진 안내 카드
class _InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle; // ✅ 1) required 제거 (옵셔널)
  final List<String> bullets;
  final TextStyle? titleStyle; // 두 타이틀 통일용

  const _InfoCard({
    required this.title,
    this.subtitle, // nullable
    required this.bullets,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = (subtitle != null) && (subtitle!.trim().isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle ?? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (hasSubtitle) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 12),
          ...bullets.map((b) => _Bullet(text: b)),
        ],
      ),
    );
  }
}

/// 아코디언(떠오르는 애니메이션 + 통일된 타이틀 스타일)
class _AccordionConsentCard extends StatelessWidget {
  final String title;
  final String sub_title;
  final Widget body;
  final bool expanded;
  final VoidCallback onToggle;
  final TextStyle? titleStyle;

  const _AccordionConsentCard({
    required this.title,
    required this.sub_title,
    required this.body,
    required this.expanded,
    required this.onToggle,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = expanded ? AppColors.primaryBlue : Colors.grey.shade300;

    // ✅ 서브타이틀/본문 공통 스타일
    final subAndBodyStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontSize: 13,color: Colors.grey.shade800);

    final BodyStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontSize: 11,color: Colors.grey.shade600);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: expanded ? 1.2 : 1),
      ),
      child: Column(
        children: [
          // 헤더: 타이틀 + 화살표만
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: titleStyle ??
                          Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // 펼쳤을 때만: 서브타이틀 + 본문
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: expanded
                ? Padding(
              key: const ValueKey('expanded'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 서브타이틀
                  Text(
                    sub_title,
                    style: subAndBodyStyle,
                  ),
                  const SizedBox(height: 14),
                  // 본문: 같은 스타일 적용
                  DefaultTextStyle(
                    style: BodyStyle ?? const TextStyle(),
                    child: body,
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(key: ValueKey('collapsed')),
          ),
        ],
      ),
    );
  }
}



class _AccordionBody extends StatelessWidget {
  const _AccordionBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const _Bullet(
          text: '증권시장에 상장되어 있지 아니한 증권으로써 향후 상장이 확정되지 \n아니한 증권',
        ),
        const _Bullet(text: '증권시장에서 투자경고종목, 투자위험종목, 관리종목으로 지정된 경우'),
        const _Bullet(text: '투자적격등급에 미치지 아니하거나 신용등급을 받지 아니한 사채권, \n자산유동화증권, 기업어음증권 및 이에 준하는 고위험 채무증권'),
        const _Bullet(text: '신용거래 및 투자자예탁재산규모에 비추어 결제가 곤란한 증권거래'),
        const _Bullet(text: '파생상품 등(파생상품, 파생결합증권, 파생상품 투자펀드)'),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 7, right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue,
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

void main() {
  runApp(const _ConsentPreviewApp());
}

class _ConsentPreviewApp extends StatelessWidget {
  const _ConsentPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consent Preview',
      debugShowCheckedModeBanner: false,
      // AppColors.primaryBlue가 있으면 테마에 살짝 반영
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        useMaterial3: true,
      ),
      home: ConsentStepPage(
        // 서버 저장 흉내(로딩 스피너 확인용)
        onSubmit: (agreed) async {
          await Future.delayed(const Duration(milliseconds: 400));
        },
        // 다음 버튼 누르면 알림만 띄우고 이동은 안 함(디자인 확인용)
        onNext: () {
          // 필요하면 라우팅으로 교체
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('다음 단계로 이동(프리뷰)')));
        },
      ),
      navigatorKey: navigatorKey,
    );
  }
}

// SnackBar용 navigatorKey (필수는 아님)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();