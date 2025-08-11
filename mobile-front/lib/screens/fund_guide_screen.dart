import 'package:flutter/material.dart';

const _primary = Color(0xFF0064FF);

class FundGuideScreen extends StatelessWidget {
  const FundGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: '뒤로 가기',
        ),
        title: const Text('펀드 이용 가이드'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _headline('저금리 시대의 자산운용 전략'),
          _strategyTable(),
          const SizedBox(height: 16),
          _headline('수익증권 용어해설'),
          _term('투자신탁',
              '자산운용사가 다수 투자자로부터 모은 자금을 유가증권 등에 투자하여 수익을 배분하는 간접투자 제도입니다.'),
          _term('수익증권',
              '투자재산의 결과를 투자자에게 배분하는 권리를 표현하는 증권입니다.'),
          _term('펀드(Fund)',
              '집합투자재산을 운용하기 위한 일종의 운용풀(POOL)입니다.'),
          _term('기준가격',
              '매일 공시되며 펀드의 평가 기준이 되는 가격입니다.'),
          _term('과표기준가격',
              '세금 산정 시 기준이 되는 가격으로, 과세체계에 따라 상이할 수 있습니다.'),
          _term('잔고좌수',
              '보유 좌수로 투자자의 수익 계산의 기준이 됩니다.'),
          _term('재투자', '분배금을 다시 같은 펀드에 투자하는 것을 말합니다.'),
          _term('환매', '보유한 수익증권을 매도하여 현금화하는 절차입니다.'),
          _term('환매수수료',
              '약관에서 정한 기간 내 환매 시 부과될 수 있는 수수료입니다.'),
          _term('위탁회사/수탁회사/판매회사',
              '각각 운용, 보관/관리, 판매를 담당하는 기관입니다.'),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFFFFFAEE),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '투자 전 (간이)투자설명서 및 약관을 반드시 읽어보세요. '
                    '과거의 수익률은 미래의 수익률을 보장하지 않습니다.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headline(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
  );

  Widget _term(String title, String desc) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, height: 1.45),
              children: [
                TextSpan(
                    text: '$title  ',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _strategyTable() {
    final rows = const [
      ['채권형', '집합자산의 60% 이상을 채권(금리성)으로 운용'],
      ['주식형', '집합자산의 60% 이상을 주식(주가연계상품 포함)으로 운용'],
      ['혼합형', '주식·채권을 혼합 운용'],
      ['MMF', '단기금융상품(CP, CD, CALL 등) 위주로 운용'],
      ['해외투자형', '해외자산에 분산 투자하여 안정/성장 추구'],
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth()},
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.shade200),
          outside: BorderSide(color: Colors.grey.shade300),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: const [
              _Th('분류'),
              _Th('설명'),
            ],
          ),
          ...rows.map((r) => TableRow(children: [ _Td(r[0]), _Td(r[1]) ])),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String t;
  const _Th(this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(t,
        style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _Td extends StatelessWidget {
  final String t;
  const _Td(this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(t),
  );
}