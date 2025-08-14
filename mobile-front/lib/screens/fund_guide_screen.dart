import 'package:flutter/material.dart';

const _primary = Color(0xFF0064FF);

class FundGuideScreen extends StatelessWidget {
  const FundGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: '뒤로 가기',
        ),
        title: const Text('펀드 이용 가이드'),
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // 상단 배너
          _HeroBanner(
            title: '펀드, 핵심만 빠르게 이해하기',
            caption: '저금리 시대의 자산운용 전략과 필수 용어를 한 눈에 정리했어요.',
          ),
          const SizedBox(height: 25),

          // 섹션 1: 전략
          _SectionCard(
            icon: Icons.trending_up_rounded,
            title: '저금리 시대의 자산운용 전략',
            child: _StrategyTable(),
          ),
          const SizedBox(height: 16),

          // 섹션 2: 용어
          _SectionCard(
            icon: Icons.menu_book_outlined,
            title: '수익증권 용어해설',
            trailing: _TipPill(text: '핵심 요약'),
            child: Column(
              children: const [
                _GlossaryItem(
                  term: '투자신탁',
                  desc:
                  '자산운용사가 다수 투자자로부터 모은 자금을 유가증권 등에 투자하여 수익을 배분하는 간접투자 제도.',
                ),
                _GlossaryItem(
                  term: '수익증권',
                  desc: '투자재산의 운용 결과에 따른 이익 배분을 받을 권리를 표현하는 증권.',
                ),
                _GlossaryItem(
                  term: '펀드(Fund)',
                  desc: '집합투자재산을 운용하기 위한 자금의 풀(POOL).',
                ),
                _GlossaryItem(
                  term: '기준가격',
                  desc: '매일 공시되는 펀드 평가 기준 가격. 매입/환매의 기준이 됨.',
                ),
                _GlossaryItem(
                  term: '과표기준가격',
                  desc: '세금 산정 시 기준이 되는 가격(과세체계에 따라 상이).',
                ),
                _GlossaryItem(
                  term: '잔고좌수',
                  desc: '보유 좌수. 투자자의 수익 계산 기준.',
                ),
                _GlossaryItem(
                  term: '재투자',
                  desc: '분배금을 다시 동일 펀드에 투자하는 것.',
                ),
                _GlossaryItem(
                  term: '환매',
                  desc: '보유 수익증권을 매도하여 현금화하는 절차.',
                ),
                _GlossaryItem(
                  term: '환매수수료',
                  desc: '약관에서 정한 기간 내 환매 시 부과될 수 있는 수수료.',
                ),
                _GlossaryItem(
                  term: '위탁회사/수탁회사/판매회사',
                  desc: '각각 운용, 보관/관리, 판매를 담당하는 기관.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 디스클레이머
          Card(
            color: const Color(0xFFFFFAEE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '투자 전 (간이)투자설명서 및 약관을 반드시 읽어보세요.\n'
                    '과거의 수익률은 미래의 수익률을 보장하지 않습니다.',
                style: TextStyle(height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- 위젯들 ---------- */

class _HeroBanner extends StatelessWidget {
  final String title;
  final String caption;
  const _HeroBanner({required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_primary, Color(0xFF2E7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    )),
                const SizedBox(height: 6),
                Text(
                  caption,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: .8,
      surfaceTintColor: Colors.white,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primary),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _TipPill extends StatelessWidget {
  final String text;
  const _TipPill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCCE0FF)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GlossaryItem extends StatelessWidget {
  final String term;
  final String desc;
  const _GlossaryItem({required this.term, required this.desc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: false,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF5FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.check, color: _primary, size: 18),
      ),
      title: Text(
        term,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          desc,
          style: const TextStyle(height: 1.45, color: Colors.black87),
        ),
      ),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      minLeadingWidth: 0,
    );
  }
}

class _StrategyTable extends StatelessWidget {
  const _StrategyTable();

  @override
  Widget build(BuildContext context) {
    final rows = const [
      ['채권형', '집합자산의 60% 이상을 채권(금리성)으로 운용'],
      ['주식형', '집합자산의 60% 이상을 주식(주가연계상품 포함)으로 운용'],
      ['혼합형', '주식·채권을 혼합 운용'],
      ['MMF', '단기금융상품(CP, CD, CALL 등) 위주로 운용'],
      ['해외투자형', '해외자산에 분산 투자하여 안정/성장 추구'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFFF3F7FF),
            child: Row(
              children: const [
                Expanded(
                  flex: 26,
                  child: Text('분류',
                      style: TextStyle(fontWeight: FontWeight.w900, color: _primary)),
                ),
                Expanded(
                  flex: 74,
                  child: Text('설명', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          // 본문
          ...List.generate(rows.length, (i) {
            final zebra = i.isEven ? Colors.white : const Color(0xFFFAFBFE);
            return Container(
              color: zebra,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 26,
                    child: Text(
                      rows[i][0],
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 74,
                    child: Text(
                      rows[i][1],
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
