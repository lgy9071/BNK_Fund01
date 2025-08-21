import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/services/invest_result_service.dart';
import 'package:mobile_front/widgets/show_custom_confirm_dialog.dart';

class InvestTypeResultScreen extends StatefulWidget {
  /// 최신 분석 결과 (없으면 null)
  final InvestResultModel? result;

  /// 재분석 가능 여부(서버 판단만 사용)
  final InvestEligibilityResponse eligibility;

  /// 분석/재분석 시작 콜백 (설문 라우팅)
  final Future<bool?> Function()? onStartAssessment;

  const InvestTypeResultScreen({
    super.key,
    required this.result,
    required this.eligibility,
    this.onStartAssessment,
  });

  @override
  State<InvestTypeResultScreen> createState() => _InvestTypeResultScreenState();
}

class _InvestTypeResultScreenState extends State<InvestTypeResultScreen> {
  bool _showRiskMap = false;   // 금융투자상품 투자위험지도
  bool _showTypeGuide = false; // 투자유형안내

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _handleStartAssessment(BuildContext context) async {
    // ✅ 클라에서 24시간 로직 제거. 서버 eligibility만 따른다.
    if (!widget.eligibility.canReanalyze) {
      final msg = widget.eligibility.message ?? '오늘은 재검사가 제한됩니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    // 정책 확인 팝업
    final bool? confirmed = await showAppConfirmDialog(
      context: context,
      title: '재검사 정책 확인',
      message: '• 투자성향 검사는 1년마다 재실시해야 합니다\n'
          '• 재검사는 하루에 한 번만 가능합니다\n\n'
          '위 정책 확인 후 계속 진행을 눌러주세요',
      confirmText: '계속 진행',
      cancelText: '취소',
      showCancel: true,
      barrierDismissible: true,
      confirmColor: AppColors.primaryBlue,
    );

    if (confirmed != true) return;

    if (widget.onStartAssessment != null) {
      final bool? ok = await widget.onStartAssessment!(); // 설문 진입
      if (ok == true && mounted) {
        Navigator.of(context).pop(true); // 도입부 닫고 상위로 true 전파(새로고침 신호)
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재검사를 시작합니다. 라우팅을 연결해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.fontColor;
    final r = widget.result;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('투자성향분석'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: base,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('투자자정보확인'),
              const SizedBox(height: 8),

              // ===== 상단: 결과 유무에 따라 분기 =====
              if (r == null) ...[
                _EmptyDataCard(onStart: () => _handleStartAssessment(context)),
              ] else ...[
                _InfoCard(children: [
                  _pair('등급결정일자', _ymd(r.analysisDate)),
                  _pair('총점', '${r.totalScore}점'),
                  _pair('투자성향', r.typeName),
                ]),
                const SizedBox(height: 8),
                _ResultGraphCard(riskType: r.typeName),
                // 유형 설명 안내
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    r.description,
                    style: TextStyle(color: AppColors.fontColor.withOpacity(.8)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // ✅ 정책 안내 박스(오늘 가능 여부는 eligibility로만 표시)
              _PolicyNotice(
                assessedAt: r?.analysisDate,
                todayBlocked: !widget.eligibility.canReanalyze,
                serverMessage: widget.eligibility.message,
              ),

              const SizedBox(height: 24),

              // ===== 투자위험지도 (텍스트 전체 탭 + 화살표 아이콘) =====
              _ExpandableHeader(
                title: '금융투자상품 투자위험지도',
                expanded: _showRiskMap,
                onToggle: () => setState(() => _showRiskMap = !_showRiskMap),
              ),
              if (_showRiskMap) ...[
                const SizedBox(height: 8),
                const _RiskMatrixTable(),
              ],

              const SizedBox(height: 24),

              // ===== 투자유형안내 (텍스트 전체 탭 + 화살표 아이콘) =====
              _ExpandableHeader(
                title: '투자유형안내',
                expanded: _showTypeGuide,
                onToggle: () => setState(() => _showTypeGuide = !_showTypeGuide),
              ),
              if (_showTypeGuide) ...[
                const SizedBox(height: 8),
                const _TypeGuideTable(),
              ],

              const SizedBox(height: 32),

              // ===== 하단 버튼: 결과가 있을 때만 재분석 시작 (정책은 eligibility로 제어)
              if (r != null) ...[
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0064FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: widget.eligibility.canReanalyze
                          ? () => _handleStartAssessment(context)
                          : null, // 🚫 불가 시 버튼 비활성화
                      child: const Text(
                        '재분석 시작',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                if (!widget.eligibility.canReanalyze) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '재검사 가능일자: ${_ymd(DateTime.now().add(const Duration(days: 1)))}',
                      style: TextStyle(
                        color: AppColors.fontColor.withOpacity(.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pair(String k, String v) => Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(k, style: TextStyle(color: AppColors.fontColor.withOpacity(.75))),
      ),
      Expanded(
        child: Text(
          v,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.fontColor),
        ),
      ),
    ],
  );
}

/* ---------- 서브 위젯들 ---------- */

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: AppColors.fontColor,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0064FF).withOpacity(.12)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 16, color: Colors.black12.withOpacity(.08)),
          ],
        ],
      ),
    );
  }
}

class _ResultGraphCard extends StatelessWidget {
  final String riskType;
  const _ResultGraphCard({required this.riskType});

  int _indexOfType(String t) {
    const order = ['안정형', '안정추구형', '위험중립형', '적극투자형', '공격투자형'];
    final i = order.indexOf(t);
    return i < 0 ? 2 : i; // 기본: 중립
  }

  @override
  Widget build(BuildContext context) {
    final idx = _indexOfType(riskType);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0064FF).withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            riskType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.fontColor,
            ),
          ),
          const SizedBox(height: 12),
          _RiskPositionBar(activeIndex: idx),
          const SizedBox(height: 8),
          Text(
            '시장평균 대비 변동성 수용수준과 손실 감내 정도를 바탕으로 산출된 결과입니다.',
            style: TextStyle(color: AppColors.fontColor.withOpacity(.8)),
          ),
        ],
      ),
    );
  }
}

class _RiskPositionBar extends StatelessWidget {
  final int activeIndex; // 0~4
  const _RiskPositionBar({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    const labels = ['안정', '안정추구', '중립', '적극', '공격'];
    return Column(
      children: [
        Row(
          children: List.generate(5, (i) {
            final isOn = i <= activeIndex;
            return Expanded(
              child: Container(
                height: 10,
                margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isOn ? const Color(0xFF0064FF) : const Color(0xFFE7ECFF),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            5,
                (i) => Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: i == activeIndex ? FontWeight.w800 : FontWeight.w400,
                color: i == activeIndex
                    ? AppColors.fontColor
                    : AppColors.fontColor.withOpacity(.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RiskMatrixTable extends StatelessWidget {
  const _RiskMatrixTable();

  Widget row(String grade, List<String> cols, {Color? bg}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0064FF).withOpacity(.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grade,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.fontColor,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < cols.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: i.isEven ? const Color(0xFFF8FAFF) : Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0064FF).withOpacity(.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${i + 1}등급',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.fontColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cols[i],
                      style: const TextStyle(fontSize: 14, color: AppColors.fontColor),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        row('선정지표', [
          'VaR 97.5%',
          'VaR 50% 초과',
          'VaR 30% 이하',
          'VaR 20% 이하',
          'VaR 10% 이하',
          'VaR 1% 이하'
        ]),
        row('펀드/ETF', [
          '레버리지·고위험',
          '수익률 변동성↑',
          '고위험채권 80%↑',
          '채권형 50% 미만',
          '저위험채(주로) 60%↑',
          '단기금융 중심'
        ]),
        row('채권/예금', [
          'B이하',
          'BB~BB-',
          'BBB+~BBB-',
          'A-~A+',
          'AA-~A+',
          '국공채·보증채'
        ]),
      ],
    );
  }
}

class _TypeGuideTable extends StatelessWidget {
  const _TypeGuideTable();

  TableRow tr(String a, String b, {bool head = false}) {
    final style = TextStyle(
      fontWeight: head ? FontWeight.w700 : FontWeight.w400,
      color: AppColors.fontColor,
    );
    return TableRow(children: [
      Padding(padding: const EdgeInsets.all(10), child: Text(a, style: style)),
      Padding(padding: const EdgeInsets.all(10), child: Text(b, style: style)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.black12),
      columnWidths: const {0: FlexColumnWidth(1.0), 1: FlexColumnWidth(2.2)},
      children: [
        tr('투자유형', '설명', head: true),
        tr('안정형', '예금 또는 저축 수준의 수익률을 기대하며, 원금손실에 매우 민감한 투자자'),
        tr('안정추구형', '원금손실 최소화, 다만 낮은 수준의 위험 감내 가능'),
        tr('위험중립형', '수익과 위험의 균형을 중시, 일정 수준의 손실 감내'),
        tr('적극투자형', '평균 이상 수익을 위해 위험을 감내할 수 있음'),
        tr('공격투자형', '고수익을 위해 높은 변동성과 손실 가능성을 감내'),
      ],
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final String text;
  const _NoticeBox({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        border: Border.all(color: const Color(0xFFDD7664)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF7B2B1C))),
    );
  }
}

/// 정책 안내 + 다음 정기 재검사일/오늘 가능 여부 표시(서버 응답만 반영)
class _PolicyNotice extends StatelessWidget {
  final DateTime? assessedAt;
  final bool todayBlocked;       // eligibility 기반
  final String? serverMessage;   // 서버 메시지

  const _PolicyNotice({
    required this.assessedAt,
    required this.todayBlocked,
    required this.serverMessage,
  });

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final nextAnnual = assessedAt != null
        ? DateTime(assessedAt!.year + 1, assessedAt!.month, assessedAt!.day)
        : null;

    final lines = <String>[
      '정책 안내',
      '• 투자성향 검사는 1년마다 재실시해야 합니다.'
          '${nextAnnual != null ? ' (다음 정기 재검사일: ${_ymd(nextAnnual)})' : ''}',
      '• 재검사는 하루에 한 번만 가능합니다.'
          '${todayBlocked ? ' (오늘 재검사 불가)' : ''}',
      if (serverMessage != null && serverMessage!.isNotEmpty) '• $serverMessage',
    ];

    return _NoticeBox(text: lines.join('\n'));
  }
}

/// 결과가 없을 때: 상단에만 "분석 시작" 버튼
class _EmptyDataCard extends StatelessWidget {
  final VoidCallback onStart;
  const _EmptyDataCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0064FF).withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '투자성향 데이터가 없습니다.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.fontColor),
          ),
          const SizedBox(height: 8),
          Text(
            '분석을 먼저 진행해주세요. 분석 완료 후 개인별 결과\n(그래프/정보)가 표시됩니다.\n'
                '아래의 “투자위험지도/투자유형안내”는 가이드로 언제든 확인할 수 있습니다.',
            style: TextStyle(color: AppColors.fontColor.withOpacity(.85)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('분석 시작'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  const _ExpandableHeader({
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: _SectionTitle(title)),
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }
}
