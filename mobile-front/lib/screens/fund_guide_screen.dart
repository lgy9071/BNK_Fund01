import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class FundGuideScreen extends StatelessWidget {
  const FundGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.fontColor),
          onPressed: () => Navigator.pop(context),
          tooltip: '뒤로 가기',
        ),
        title: const Text(
          '펀드 이용 가이드',
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white, // 전체 배경은 흰색
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: const [
          _HeroBanner(
            title: '펀드, 핵심만 빠르게 이해하기',
          ),
          SizedBox(height: 20),
          _SectionCard(
            icon: Icons.trending_up_rounded,
            title: '저금리 시대의 자산운용 전략',
            child: _StrategyTable(),
          ),
          SizedBox(height: 12),
          _SectionCard(
            icon: Icons.menu_book_outlined,
            title: '수익증권 용어해설',
            trailing: _TipPill(text: '핵심 요약'),
            child: _GlossaryList(),
          ),
          SizedBox(height: 12),
          _Disclaimer(),
        ],
      ),
    );
  }
}

/* ---------- 컴포넌트 ---------- */

class _HeroBanner extends StatelessWidget {
  final String title;
  const _HeroBanner({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg, // 라이트 블루 배경
        borderRadius: BorderRadius.circular(10), // 모서리 둥글게
        border: Border.all(color: const Color(0xFFCCE0FF)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.fontColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // 카드도 단색
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECF7)), // 라이트 톤 보더
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 라인
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.bg, // 연블루 라운드 박스에
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.fontColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEAEFF8)),
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
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCCE0FF)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/* ---------- 용어 리스트: 라이트 스타일 ---------- */

class _GlossaryList extends StatelessWidget {
  const _GlossaryList();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('투자신탁', '자산운용사가 다수 투자자로부터 모은 자금을 유가증권 등에 투자하여 수익을 배분하는 간접투자 제도.'),
      ('수익증권', '투자재산의 운용 결과에 따른 이익 배분을 받을 권리를 표현하는 증권.'),
      ('펀드(Fund)', '집합투자재산을 운용하기 위한 자금의 풀(POOL).'),
      ('기준가격', '매일 공시되는 펀드 평가 기준 가격. 매입/환매의 기준이 됨.'),
      ('과표기준가격', '세금 산정 시 기준이 되는 가격(과세체계에 따라 상이).'),
      ('잔고좌수', '보유 좌수. 투자자의 수익 계산 기준.'),
      ('재투자', '분배금을 다시 동일 펀드에 투자하는 것.'),
      ('환매', '보유 수익증권을 매도하여 현금화하는 절차.'),
      ('환매수수료', '약관에서 정한 기간 내 환매 시 부과될 수 있는 수수료.'),
      ('위탁/수탁/판매회사', '각각 운용, 보관/관리, 판매를 담당하는 기관.'),
    ];

    return Column(
      children: List.generate(items.length, (i) {
        final (term, desc) = items[i];
        return _GlossaryItem(term: term, desc: desc, isLast: i == items.length - 1);
      }),
    );
  }
}

class _GlossaryItem extends StatelessWidget {
  final String term;
  final String desc;
  final bool isLast;
  const _GlossaryItem({required this.term, required this.desc, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 체크 아이콘 라이트 톤
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check, color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 10),
          // 텍스트 블록
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(term,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      color: AppColors.fontColor,
                    )),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(height: 1.45, color: AppColors.fontColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- 전략 테이블: 단색 헤더 + 라이트 지브라 ---------- */

class _StrategyTable extends StatelessWidget {
  const _StrategyTable();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['채권형', '집합자산의 60% 이상을 채권(금리성)으로 운용'],
      ['주식형', '집합자산의 60% 이상을 주식(주가연계상품 포함)으로 운용'],
      ['혼합형', '주식·채권을 혼합 운용'],
      ['MMF', '단기금융상품(CP, CD, CALL 등) 위주로 운용'],
      ['해외투자형', '해외자산에 분산 투자하여 안정/성장 추구'],
    ];

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.bg, // 단색 헤더
            child: const Row(
              children: [
                Expanded(
                  flex: 26,
                  child: Text('분류',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryBlue,
                      )),
                ),
                Expanded(
                  flex: 74,
                  child: Text('설명',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.fontColor,
                      )),
                ),
              ],
            ),
          ),
          // 본문 (지브라)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE7ECF7)),
              color: Colors.white,
            ),
            child: Column(
              children: List.generate(rows.length, (i) {
                final bg = i.isEven ? Colors.white : AppColors.bg.withOpacity(.55);
                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 26,
                        child: Text(
                          rows[i][0],
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.fontColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 74,
                        child: Text(
                          rows[i][1],
                          style: const TextStyle(
                            height: 1.45,
                            color: AppColors.fontColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- 디스클레이머: 라이트 박스 ---------- */

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0), // 밝은 주황 톤 배경
        border: Border.all(color: const Color(0xFFDD7664)), // 테두리 강조
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '투자 전 (간이)투자설명서 및 약관을 반드시 읽어보세요.\n'
            '과거의 수익률은 미래의 수익률을 보장하지 않습니다.',
        style: TextStyle(
          height: 1.45,
          color: Color(0xFF7B2B1C), // 텍스트 색도 강조
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
