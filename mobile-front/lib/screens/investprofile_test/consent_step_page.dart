import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('투자성향분석 동의'), centerTitle: true),
      body: Column(
        children: [
          const StepHeader(bigStep: 1,  showBigProgress: false), // 큰 단계만 표시 (1/3)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                SizedBox(height: 30,),
                _InfoCard(
                  title: '투자성향분석',
                  // 1) subtitle 옵셔널 — 필요 없으면 빼거나 null 전달
                  // subtitle: null,
                  bullets: const [
                    '고객님은 자본시장통합법 시행세칙에 의거 일반고객으로 분류되었음을 알려드립니다.',
                    '고객님의 투자 성향을 파악하여 적합한 상품 권유를 위한 기초 자료로 활용됩니다.',
                  ],
                  titleStyle: titleStyleUnified,
                ),
                const SizedBox(height: 12),

                // 2) 아코디언(타이틀 글자 크기 통일)
                _AccordionConsentCard(
                  title: '투자자정보확인서 작성 동의 (필수)',
                  expanded: expandInvestorInfo,
                  onToggle: () => setState(() => expandInvestorInfo = !expandInvestorInfo),
                  body: const _AccordionBody(),
                  titleStyle: titleStyleUnified,
                ),

                // 3) ✅ 체크박스는 박스 "밖" (아코디언 하단)에 배치
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: agreeInvestorInfo,
                      onChanged: (v) => setState(() => agreeInvestorInfo = v ?? false),
                      activeColor: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text('투자성향분석 진행에 동의합니다', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),

          // 하단 CTA
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (agreeInvestorInfo && !submitting) ? _handleNext : null,
                  child: submitting
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                      : const Text('다음'),
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
  final Widget body;
  final bool expanded;
  final VoidCallback onToggle;
  final TextStyle? titleStyle; // ✅ 2) 타이틀 통일

  const _AccordionConsentCard({
    required this.title,
    required this.body,
    required this.expanded,
    required this.onToggle,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = expanded ? AppColors.primaryBlue : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: expanded ? 1.2 : 1),
      ),
      child: Column(
        children: [
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
                      // ✅ 2) 통일된 타이틀 사용
                      style: titleStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

          // ✅ 4) "떠오르는" 느낌: Fade + 위로 살짝 Slide + Size 보정
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: expanded
                ? Padding(
              key: const ValueKey('expanded'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: body,
            )
                : const SizedBox(
              key: ValueKey('collapsed'),
              height: 0,
            ),
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
          text: '투자자정보확인서를 작성하지 않을 경우 일부 금융투자상품에 대한 투자 권유 및 일반투자자로서 보호를 받지 못할 수 있습니다.',
        ),
        const _Bullet(text: '상장 예정이거나 상장 확정이 아닌 증권 등은 높은 위험을 수반할 수 있습니다.'),
        const _Bullet(text: '투자적합등급 미달, 투자경험 부족, 관리종목 지정 등 특정 조건에서는 제한이 있을 수 있습니다.'),
        const _Bullet(text: '신용거래, 파생상품 등은 손실 위험이 크니 유의하시기 바랍니다.'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '※ 자세한 내용은 약관 전문을 확인해 주세요.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
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
            width: 6,
            height: 6,
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