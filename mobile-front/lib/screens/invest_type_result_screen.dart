import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

/// ===== 결과 모델 (백엔드 응답과 매핑) =====
class InvestResultModel {
  final String userId;
  final DateTime analysisDate;
  final int totalScore;
  final int typeId;
  final String typeName;
  final String typeDescription;

  // 선택(있으면 표시)
  final String? investorName;
  final String? investHorizon;
  final String? goal;
  final String? experience;

  const InvestResultModel({
    required this.userId,
    required this.analysisDate,
    required this.totalScore,
    required this.typeId,
    required this.typeName,
    required this.typeDescription,
    this.investorName,
    this.investHorizon,
    this.goal,
    this.experience,
  });

  factory InvestResultModel.fromJson(Map<String, dynamic> j) {
    return InvestResultModel(
      userId: j['userId'],
      analysisDate: DateTime.parse(j['analysisDate']),
      totalScore: j['totalScore'],
      typeId: j['type']['id'],
      typeName: j['type']['name'],
      typeDescription: j['type']['description'],
      investorName: j['investorName'],
      investHorizon: j['investHorizon'],
      goal: j['goal'],
      experience: j['experience'],
    );
  }
}

/// ===== 스크린 =====
class InvestTypeResultScreen extends StatefulWidget {
  /// 최신 분석 결과 (없으면 null)
  final InvestResultModel? result;

  /// 마지막 재검사 시각 (하루 1회 제한 체크용)
  final DateTime? lastRetestAt;

  /// 분석/재분석 시작 콜백
  final VoidCallback? onStartAssessment;

  const InvestTypeResultScreen({
    super.key,
    this.result,
    this.lastRetestAt,
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _handleStartAssessment(BuildContext context) async {
    final now = DateTime.now();
    final alreadyToday =
        widget.lastRetestAt != null && _isSameDay(widget.lastRetestAt!, now);
    if (alreadyToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘은 이미 재검사를 진행하셨습니다. 내일 다시 시도해주세요.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('재검사 정책 확인'),
        content: const Text(
            '• 투자성향 검사는 1년마다 재실시해야 합니다.\n'
                '• 재검사는 하루에 한 번만 가능합니다.\n\n'
                '위 정책을 확인하셨다면 계속 진행을 눌러주세요.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onStartAssessment != null) {
                widget.onStartAssessment!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('재검사를 시작합니다. 라우팅을 연결해주세요.')),
                );
              }
            },
            child: const Text('계속 진행'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.fontColor;
    final r = widget.result;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('투자성향 결과'),
        backgroundColor: Colors.white,
        foregroundColor: base,
        elevation: 0.5,
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
                  _pair('사용자', r.investorName ?? r.userId),
                  _pair('등급결정일자', _ymd(r.analysisDate)),
                  _pair('총점', '${r.totalScore}점'),
                  _pair('투자성향', r.typeName),
                  if (r.investHorizon != null) _pair('투자기간', r.investHorizon!),
                  if (r.goal != null) _pair('투자목표', r.goal!),
                  if (r.experience != null) _pair('투자경험', r.experience!),
                ]),
                const SizedBox(height: 8),
                _ResultGraphCard(riskType: r.typeName),
                // 유형 설명 안내
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    r.typeDescription,
                    style: TextStyle(color: AppColors.fontColor.withOpacity(.8)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              _PolicyNotice(assessedAt: r?.analysisDate, lastRetestAt: widget.lastRetestAt),

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

              // ===== 하단 버튼: 결과가 있을 때만 재분석 시작 =====
              if (r != null)
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
                      onPressed: () => _handleStartAssessment(context),
                      child: const Text('재분석 시작',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),

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
          Text(riskType,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.fontColor)),
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

/// 텍스트 전체 탭 + 우측 화살표 아이콘
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

/// 정책 안내 + 다음 정기 재검사일/오늘 가능 여부 표시
class _PolicyNotice extends StatelessWidget {
  final DateTime? assessedAt;
  final DateTime? lastRetestAt;
  const _PolicyNotice({required this.assessedAt, required this.lastRetestAt});

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextAnnual = assessedAt != null
        ? DateTime(assessedAt!.year + 1, assessedAt!.month, assessedAt!.day)
        : null;
    final todayBlocked = lastRetestAt != null && _isSameDay(lastRetestAt!, now);

    final lines = <String>[
      '정책 안내',
      '• 투자성향 검사는 1년마다 재실시해야 합니다.'
          '${nextAnnual != null ? ' (다음 정기 재검사일: ${_ymd(nextAnnual)})' : ''}',
      '• 재검사는 하루에 한 번만 가능합니다.'
          '${todayBlocked ? ' (오늘 재검사 불가: 이미 실시)' : ''}',
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
          const Text('투자성향 데이터가 없습니다.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.fontColor)),
          const SizedBox(height: 8),
          Text(
            '분석을 먼저 진행해주세요. 분석 완료 후 개인별 결과(그래프/정보)가 표시됩니다.\n'
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
            ),
          ),
        ],
      ),
    );
  }
}