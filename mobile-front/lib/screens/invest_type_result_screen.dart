import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class InvestProfile {
  final String investorName;
  final String riskType;
  final DateTime assessedAt;
  final String investHorizon;
  final String goal;
  final String experience;
  const InvestProfile({
    required this.investorName,
    required this.riskType,
    required this.assessedAt,
    required this.investHorizon,
    required this.goal,
    required this.experience,
  });
}

class InvestTypeResultScreen extends StatefulWidget {
  const InvestTypeResultScreen({super.key});

  @override
  State<InvestTypeResultScreen> createState() => _InvestTypeResultScreenState();
}

class _InvestTypeResultScreenState extends State<InvestTypeResultScreen> {
  // 고정 더미(공격투자형)
  static final InvestProfile _dummy = InvestProfile(
    investorName: '이뚜리',
    riskType: '공격투자형',
    assessedAt: DateTime(2025, 7, 7),
    investHorizon: '1년 이상 ~ 2년 미만',
    goal: '자본이득 추구',
    experience: '3년 이상',
  );

  final _localPart = TextEditingController();
  final _domainInput = TextEditingController();
  String _domain = 'naver.com';
  bool _manualDomain = false;
  bool _agreeGuide = false;

  @override
  void dispose() {
    _localPart.dispose();
    _domainInput.dispose();
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final base = AppColors.fontColor;
    final p = _dummy;

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
              _InfoCard(children: [
                _pair('투자자(고객)명', p.investorName),
                _pair('투자목표', p.goal),
                _pair('등급결정일자', _ymd(p.assessedAt)),
                _pair('투자기간', p.investHorizon),
                _pair('투자경험', p.experience),
                _pair('투자성향', p.riskType),
              ]),
              const SizedBox(height: 8),

              // 성향 "위치 바" 그래프
              _ResultGraphCard(riskType: p.riskType),

              const SizedBox(height: 24),

              const _SectionTitle('금융투자상품 투자위험지도'),
              const SizedBox(height: 8),

              // 가로 스크롤로 안 잘리게
              const _RiskMatrixTable(),

              const SizedBox(height: 24),

              const _SectionTitle('투자유형안내'),
              const SizedBox(height: 8),
              const _TypeGuideTable(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _agreeGuide,
                    onChanged: (v) => setState(() => _agreeGuide = v ?? false),
                  ),
                  Expanded(
                    child: Text('문답지, 투자유형안내서 확인',
                        style: TextStyle(color: base)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _NoticeBox(
                text:
                '이전 투자성향분석에 대한 고객님의 투자 유형입니다.\n'
                    '금융소비자보호법에 따라 고객님의 투자성향분석 실시 후, 적합성·적정성원칙에 부합하는 상품만 조회 및 가입이 가능합니다.',
              ),

              const SizedBox(height: 28),

              const _SectionTitle('투자성향 결과표'),
              const SizedBox(height: 8),
              _EmailRow(
                localPart: _localPart,
                manualDomain: _manualDomain,
                domainController: _domainInput,
                domain: _domain,
                onDomainChanged: (v) => setState(() => _domain = v),
                onManualToggle: (v) => setState(() => _manualDomain = v),
                onSend: () {
                  final email = _manualDomain
                      ? '${_localPart.text}@${_domainInput.text}'
                      : '${_localPart.text}@$_domain';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('결과를 $email 으로 전송했습니다.')),
                  );
                },
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAD2E1B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _agreeGuide
                        ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('분석을 시작합니다.')),
                      );
                    }
                        : null,
                    child: const Text('분석하기',
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
        child: Text(k,
            style: TextStyle(color: AppColors.fontColor.withOpacity(.75))),
      ),
      Expanded(
        child: Text(
          v,
          textAlign: TextAlign.right,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.fontColor),
        ),
      ),
    ],
  );
}

/* ---- 서브 위젯 ---- */

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
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.fontColor)),
          const SizedBox(height: 12),
          _RiskPositionBar(activeIndex: idx),
          const SizedBox(height: 8),
          Text(
            '시장평균 대비 변동성 수용수준이 높고, 수익을 위해 위험을 감내하는 성향입니다.',
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
                  color: isOn
                      ? const Color(0xFF0064FF)
                      : const Color(0xFFE7ECFF),
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
                fontWeight:
                i == activeIndex ? FontWeight.w800 : FontWeight.w400,
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

  DataRow row(String grade, List<String> cols, {Color? bg}) => DataRow(
    color: bg != null ? MaterialStatePropertyAll(bg) : null,
    cells: [
      DataCell(Text(grade)),
      for (final c in cols) DataCell(Text(c, textAlign: TextAlign.center)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    const headStyle = TextStyle(fontWeight: FontWeight.w700);

    final table = DataTable(
      headingRowColor:
      MaterialStatePropertyAll(Colors.black.withOpacity(.03)),
      headingTextStyle: headStyle,
      columns: const [
        DataColumn(label: Text('구분')),
        DataColumn(label: Text('1등급')),
        DataColumn(label: Text('2등급')),
        DataColumn(label: Text('3등급')),
        DataColumn(label: Text('4등급')),
        DataColumn(label: Text('5등급')),
        DataColumn(label: Text('6등급')),
      ],
      rows: [
        row('선정지표',
            ['VaR 97.5%', 'VaR 50% 초과', 'VaR 30% 이하', 'VaR 20% 이하', 'VaR 10% 이하', 'VaR 1% 이하']),
        row('펀드/ETF',
            ['레버리지·고위험', '수익률 변동성↑', '고위험채권 80%↑', '채권형 50% 미만', '저위험채(주로) 60%↑', '단기금융 중심'],
            bg: const Color(0xFFFFF8E7)),
        row('채권/예금',
            ['B이하', 'BB~BB-', 'BBB+~BBB-', 'A-~A+', 'AA-~A+', '국공채·보증채']),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0064FF).withOpacity(.12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: table,
      ),
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

class _EmailRow extends StatelessWidget {
  final TextEditingController localPart;
  final bool manualDomain;
  final TextEditingController domainController;
  final String domain;
  final ValueChanged<String> onDomainChanged;
  final ValueChanged<bool> onManualToggle;
  final VoidCallback onSend;

  const _EmailRow({
    required this.localPart,
    required this.manualDomain,
    required this.domainController,
    required this.domain,
    required this.onDomainChanged,
    required this.onManualToggle,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppColors.fontColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0064FF).withOpacity(.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: localPart,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'your.id',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('@'),
              const SizedBox(width: 8),
              if (!manualDomain)
                DropdownButton<String>(
                  value: domain,
                  onChanged: (v) => v != null ? onDomainChanged(v) : null,
                  items: const [
                    DropdownMenuItem(value: 'naver.com', child: Text('naver.com')),
                    DropdownMenuItem(value: 'gmail.com', child: Text('gmail.com')),
                    DropdownMenuItem(value: 'daum.net', child: Text('daum.net')),
                    DropdownMenuItem(value: 'kakao.com', child: Text('kakao.com')),
                  ],
                )
              else
                Expanded(
                  child: TextField(
                    controller: domainController,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'example.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onSend, child: const Text('결과받기')),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onManualToggle(!manualDomain),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(
                manualDomain ? '도메인 목록 사용' : '도메인 직접입력',
                style: TextStyle(color: base),
              ),
            ),
          ),
        ],
      ),
    );
  }
}