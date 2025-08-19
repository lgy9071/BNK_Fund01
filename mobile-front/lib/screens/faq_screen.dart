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

  String _query = '';

  final List<FaqItem> _items = [
    // pinned
    FaqItem('펀드는 무엇인가요?',
        '여러 투자자의 자금을 모아 운용사가 다양한 자산에 투자하는 간접 투자상품입니다.',
        category: '기본', pinned: true),
    FaqItem('펀드는 어디서 가입하나요?',
        '앱의 “펀드 가입” 탭에서 비대면으로 가입 가능합니다.',
        category: '가입', pinned: true),

    // 일반
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
  bool _matchQuery(FaqItem item) {
    if (_query.trim().isEmpty) return true;
    final q = _query.toLowerCase();
    return item.q.toLowerCase().contains(q) || item.a.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 순서: pinned 먼저 → 일반
    final ordered = [
      ..._pinnedIndexes.where((i) => _matchCategory(_items[i]) && _matchQuery(_items[i])),
      ..._normalIndexes.where((i) => _matchCategory(_items[i]) && _matchQuery(_items[i])),
    ];

    final totalCount = ordered.length;
    final visibleCount = _showAll ? totalCount : (totalCount < _initialCount ? totalCount : _initialCount);
    final hasMore = !_showAll && totalCount > visibleCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('자주 묻는 질문'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: .5,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── 검색 + 카테고리 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: _SearchField(
                    hint: '질문, 키워드로 검색',
                    onChanged: (v) => setState(() {
                      _query = v;
                      _showAll = true; // 검색 시는 전체 노출
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                _CountPill(count: totalCount),
              ],
            ),
          ),
          _CategoryChips(
            categories: _categories,
            selected: _selected,
            onSelected: (v) {
              setState(() {
                _selected = v;
                _query = '';
                _showAll = false;
              });
            },
          ),

          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant.withOpacity(.5)),
          const SizedBox(height: 8),

          // ── 질문 목록 영역 ──
          Expanded(
            child: Container(
              color: faqListBg,
              child: totalCount == 0
                  ? const Center(child: Text('해당 조건의 질문이 없습니다.'))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: visibleCount + (hasMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (hasMore && i == visibleCount) {
                    return _MoreButton(onTap: () => setState(() => _showAll = true));
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

/* ───────── 검색창 ───────── */

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF2F4F8),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/* ───────── 카테고리 칩 ───────── */

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
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = categories[i];
          final isSel = label == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? tossBlue : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isSel ? tossBlue : Colors.black12),
                boxShadow: [
                  if (isSel)
                    const BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isSel ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ───────── 질문 카드 ───────── */

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            initiallyExpanded: isExpanded,
            onExpansionChanged: onToggle,
            tilePadding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),

            title: Row(
              children: [
                if (item.pinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5FF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFCCE0FF)),
                    ),
                    child: const Text('고정', style: TextStyle(color: tossBlue, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                Expanded(
                  child: Text(
                    item.q,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),

            children: [
              const Divider(height: 1),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.a,
                  textAlign: TextAlign.start,
                  style: TextStyle(color: cs.onSurface, height: 1.5, fontSize: 14.5),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: '${item.q}\n\n${item.a}'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('복사되었습니다.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('복사'),
                    style: TextButton.styleFrom(
                      foregroundColor: tossBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────── 수량 표시 ───────── */

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$count개', style: const TextStyle(fontWeight: FontWeight.w800)),
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
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: SizedBox(
        height: 44,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: tossBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('더보기', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
