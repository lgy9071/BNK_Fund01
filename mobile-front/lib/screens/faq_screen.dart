import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 색상
const tossBlue = Color(0xFF0064FF);
const faqListBg = Color(0xFFF5F6F8); // 질문 목록 영역(하단) 배경

class FaqItem {
  final String q;
  final String a;
  final String category;
  final bool pinned; // 상단 고정
  FaqItem(this.q, this.a, {required this.category, this.pinned = false});
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late final List<String> _categories;
  String _selected = '전체';
  final Set<int> _expanded = {};
  bool _showAll = false; // 더보기 상태
  static const int _initialCount = 5;

  final List<FaqItem> _items = [
    // pinned 먼저(예시 2개)
    FaqItem('펀드는 무엇인가요?',
        '여러 투자자의 자금을 모아 운용사가 다양한 자산에 투자하는 간접 투자상품입니다.',
        category: '기본', pinned: true),
    FaqItem('펀드는 어디서 가입하나요?',
        '앱의 “펀드 가입” 탭에서 비대면으로 가입 가능합니다.',
        category: '가입', pinned: true),

    // 일반(총 10개 내외가 되도록 예시 추가)
    FaqItem('투자 성향 분석은 필수인가요?', '네, 투자자 보호를 위해 의무 절차입니다.', category: '규정'),
    FaqItem('펀드 위험 확인 방법은?', '상품 상세의 위험수준 카드와 설명서를 참고하세요.', category: '위험'),
    FaqItem('수수료는 어떻게 부과되나요?', '매입/환매 수수료 및 각종 보수가 있습니다.', category: '수수료'),
    FaqItem('중도 환매 시 불이익이 있나요?', '후취판매수수료 등 조건에 따라 비용이 발생할 수 있습니다.', category: '해지'),
    FaqItem('수익은 언제부터 발생하나요?', '기준가 적용 후 운용 성과에 따라 평가손익이 변동합니다.', category: '수익'),
    FaqItem('해외펀드 환헤지란 무엇인가요?', '환율 변동 위험을 줄이기 위해 파생상품을 활용하는 전략입니다.', category: '위험'),
    FaqItem('적립식/거치식 차이는?', '적립식은 분할 매수, 거치식은 일시 매수 방식입니다.', category: '가입'),
    FaqItem('세금은 어떻게 되나요?', '배당소득세 등 과세가 적용될 수 있으며 상품별로 상이합니다.', category: '세금'),
  ];

  @override
  void initState() {
    super.initState();
    final cats = _items.map((e) => e.category).toSet().toList()..sort();
    _categories = ['전체', ...cats];
  }

  List<int> get _pinnedIndexes =>
      List.generate(_items.length, (i) => i).where((i) => _items[i].pinned).toList();

  List<int> get _normalIndexes =>
      List.generate(_items.length, (i) => i).where((i) => !_items[i].pinned).toList();

  bool _matchCategory(FaqItem item) =>
      _selected == '전체' ? true : (item.category == _selected);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 순서: pinned 먼저, 그 다음 일반. (헤더 없이)
    final ordered = [
      ..._pinnedIndexes.where((i) => _matchCategory(_items[i])),
      ..._normalIndexes.where((i) => _matchCategory(_items[i])),
    ];

    // 보여줄 개수(더보기 이전엔 5개만)
    final totalCount = ordered.length;
    final visibleCount = _showAll ? totalCount : (totalCount < _initialCount ? totalCount : _initialCount);
    final hasMore = !_showAll && totalCount > visibleCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('자주 묻는 질문'),
        centerTitle: true,
        backgroundColor: Colors.white, // 상단(카테고리 영역 포함)은 흰색
        surfaceTintColor: Colors.white,
        elevation: .5,
      ),
      backgroundColor: Colors.white, // 전체 기본 흰색
      body: Column(
        children: [
          // ── 카테고리(흰 배경 영역, 리스트 배경에 포함되지 않음) ──
          _CategoryChips(
            categories: _categories,
            selected: _selected,
            onSelected: (v) {
              setState(() {
                _selected = v;
                _showAll = false; // 카테고리 바꿀 때는 다시 5개부터
              });
            },
          ),

          // 카테고리와 질문 목록 사이 간격 + 구분선
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant.withOpacity(.5)),
          const SizedBox(height: 10),

          // ── 질문 목록 영역(하단 배경색 적용: faqListBg) ──
          Expanded(
            child: Container(
              color: faqListBg,
              child: totalCount == 0
                  ? const Center(child: Text('해당 카테고리의 질문이 없습니다.'))
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: visibleCount + (hasMore ? 1 : 0), // 더보기 버튼 포함
                itemBuilder: (_, i) {
                  // 더보기 버튼
                  if (hasMore && i == visibleCount) {
                    return _MoreButton(
                      onTap: () => setState(() => _showAll = true),
                    );
                  }

                  final idx = ordered[i];
                  final item = _items[idx];
                  final isOpen = _expanded.contains(idx);

                  return _FaqCard(
                    item: item,
                    isExpanded: isOpen,
                    onToggle: (v) {
                      setState(() {
                        if (v == true) {
                          _expanded.add(idx);
                        } else {
                          _expanded.remove(idx);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────── 카테고리 칩(선택=토스블루+화이트, 미선택=텍스트만) ───────── */

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = categories[i];
          final isSel = label == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onSelected(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? tossBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ───────── 질문 카드(투명 배경) ───────── */

class _FaqCard extends StatelessWidget {
  final FaqItem item;
  final bool isExpanded;
  final ValueChanged<bool?> onToggle;
  const _FaqCard({
    required this.item,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,        // 카드 배경 투명
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isExpanded,
        onExpansionChanged: onToggle,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),

        title: Row(
          children: [
            if (item.pinned) ...[
              const Icon(Icons.push_pin, size: 16),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                item.q,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '복사',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: '${item.q}\n\n${item.a}'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('복사되었습니다.')),
                  );
                }
              },
            ),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),

        children: [
          Text(
            item.a,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/* ───────── 더보기 버튼 ───────── */

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.black.withOpacity(.2)),
          ),
          child: const Text('더보기'),
        ),
      ),
    );
  }
}