import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/widgets/step_header.dart';
import 'package:mobile_front/core/constants/colors.dart';

/// 작성동의 (큰 단계 1/3)
class ConsentStepPage extends StatefulWidget {
  final Future<bool?> Function()? onNext;
  final Future<void> Function(bool agreed)? onSubmit;

  const ConsentStepPage({
    super.key,
    this.onNext,
    this.onSubmit,
  });

  @override
  State<ConsentStepPage> createState() => _ConsentStepPageState();
}

class _ConsentStepPageState extends State<ConsentStepPage> {
  bool agreeInvestorInfo = false;  // (필수)
  bool expandInvestorInfo = false; // 아코디언
  bool submitting = false;

  bool _canCheckAgree = false;
  int _agreeRemain = 0;
  Timer? _agreeTimer;

  @override
  void dispose() {
    _agreeTimer?.cancel();
    super.dispose();
  }

  void _startAgreeCountdown() {
    _agreeTimer?.cancel();
    setState(() {
      _canCheckAgree = false;
      _agreeRemain = 3;
    });

    _agreeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_agreeRemain <= 1) {
        t.cancel();
        setState(() {
          _agreeRemain = 0;
          _canCheckAgree = true;
        });
      } else {
        setState(() {
          _agreeRemain -= 1;
        });
      }
    });
  }

  Future<void> _handleNext() async {
    if (!agreeInvestorInfo || submitting) return;

    setState(() => submitting = true);
    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(agreeInvestorInfo);
      }

      if (widget.onNext != null) {
        final needRefresh = await widget.onNext!();
        if (!mounted) return;
        if (needRefresh == true) {
          Navigator.of(context).pop(true);
        }
        return;
      }

      if (!mounted) return;
      final bool? res = await Navigator.pushNamed<bool>(
        context,
        AppRoutes.investTest,
      );

      if (res == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyleUnified = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('작성 동의'),
        centerTitle: true,
        backgroundColor: Colors.white,
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
                  sub_title:
                  '투자자 정보를 제공하지 않는 고객님께서는 다음의 금융투자상품에 대한 투자권유 및 일반투자자로서 보호받지 못할 수 있음을 \n알려드립니다.',
                  expanded: expandInvestorInfo,
                  onToggle: () {
                    setState(() {
                      expandInvestorInfo = !expandInvestorInfo;
                      if (expandInvestorInfo) {
                        _startAgreeCountdown();
                      } else {
                        _agreeTimer?.cancel();
                        _canCheckAgree = false;
                        _agreeRemain = 0;
                        // ❌ 이전에는 여기서 agreeInvestorInfo = false 로 체크 해제했음
                        // ✅ 이제는 유지되도록 주석 처리/삭제
                      }
                    });
                  },
                  body: const _AccordionBody(),
                  titleStyle: titleStyleUnified,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: agreeInvestorInfo,
                      onChanged: (_canCheckAgree && !submitting)
                          ? (val) => setState(() => agreeInvestorInfo = val ?? false)
                          : null,
                      activeColor: AppColors.primaryBlue,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: (_canCheckAgree && !submitting)
                          ? () => setState(() => agreeInvestorInfo = !agreeInvestorInfo)
                          : null,
                      child: Text('투자자정보확인서 작성 동의', style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
                if (expandInvestorInfo && !_canCheckAgree)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          '안내를 확인한 뒤 ${_agreeRemain}초 후 동의 체크가 활성화됩니다.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
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
                    backgroundColor:
                    (agreeInvestorInfo && !submitting) ? AppColors.primaryBlue : Colors.grey.shade300,
                    foregroundColor:
                    (agreeInvestorInfo && !submitting) ? Colors.white : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  onPressed: (agreeInvestorInfo && !submitting) ? _handleNext : null,
                  child: const Text('다음', style: TextStyle(fontSize: 17)),
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> bullets;
  final TextStyle? titleStyle;

  const _InfoCard({
    required this.title,
    this.subtitle,
    required this.bullets,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = (subtitle != null) && (subtitle!.trim().isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
            Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 12),
          ...bullets.map((b) => _Bullet(text: b)),
        ],
      ),
    );
  }
}

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

    final subAndBodyStyle =
    Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, color: Colors.grey.shade800);

    final bodyStyle =
    Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey.shade600);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                      style: titleStyle ??
                          Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return FadeTransition(opacity: anim, child: SlideTransition(position: slide, child: child));
            },
            child: expanded
                ? Padding(
              key: const ValueKey('expanded'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub_title, style: subAndBodyStyle),
                  const SizedBox(height: 14),
                  DefaultTextStyle(style: bodyStyle ?? const TextStyle(), child: body),
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
    return const Column(
      children: [
        _Bullet(text: '증권시장에 상장되어 있지 아니한 증권으로써 향후 상장이 확정되지 \n아니한 증권'),
        _Bullet(text: '증권시장에서 투자경고종목, 투자위험종목, 관리종목으로 지정된 경우'),
        _Bullet(text: '투자적격등급에 미치지 아니하거나 신용등급을 받지 아니한 사채권, \n자산유동화증권, 기업어음증권 및 이에 준하는 고위험 채무증권'),
        _Bullet(text: '신용거래 및 투자자예탁재산규모에 비추어 결제가 곤란한 증권거래'),
        _Bullet(text: '파생상품 등(파생상품, 파생결합증권, 파생상품 투자펀드)'),
        SizedBox(height: 8),
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
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
