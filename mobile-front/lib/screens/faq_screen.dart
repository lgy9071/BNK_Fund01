import 'package:flutter/material.dart';

class FaqItem {
  final String q;
  final String a;
  FaqItem(this.q, this.a);
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _search = TextEditingController();
  final List<FaqItem> _items = [
    FaqItem('펀드 투자 전 투자 성향 분석은 필수인가요?', '네, 투자자 보호를 위해 성향 분석은 의무 절차입니다.'),
    FaqItem('펀드 투자 위험은 어떻게 확인하나요?', '상품 상세의 “위험수준” 카드와 (간이)투자설명서를 참고하세요.'),
    FaqItem('펀드 수수료는 어떻게 부과되나요?', '매입/환매 수수료 및 운용/판매/사무/수탁 보수가 있습니다.'),
    FaqItem('펀드를 중도 해지하면 불이익이 있나요?', '후취판매수수료 등 조건에 따라 비용이 발생할 수 있습니다.'),
    FaqItem('펀드 가입 후 언제부터 수익이 발생하나요?', '기준가 적용일 이후 운용 성과에 따라 평가손익이 변동합니다.'),
    FaqItem('펀드에도 세금이 있나요?', '배당소득세 등 과세가 적용될 수 있습니다. 상품별로 확인하세요.'),
    FaqItem('펀드는 어디서 가입하나요?', '앱의 “펀드 가입” 탭에서 비대면으로 가입 가능합니다.'),
    FaqItem('펀드에는 어떤 종류가 있나요?', '주식형, 채권형, 혼합형, MMF 등 다양한 유형이 있습니다.'),
    FaqItem('펀드는 무엇인가요?', '여러 투자자의 자금을 모아 운용사가 다양한 자산에 투자하는 간접 투자상품입니다.'),
  ];

  final Set<int> _expanded = {}; // 펼쳐진 인덱스 기억

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<FaqItem> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((e) {
      final t = (e.q + ' ' + e.a).toLowerCase();
      return t.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: '뒤로 가기',
        ),
        title: const Text('자주 묻는 질문'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 상단 비주얼 + 제목
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.06),
              border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(.4))),
            ),
            child: Column(
              children: [
                const Text('자주 묻는 질문',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.emoji_people, size: 24),
                    SizedBox(width: 6),
                    Icon(Icons.psychology_alt_outlined, size: 24),
                  ],
                ),
              ],
            ),
          ),

          // 검색바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '검색어를 입력해주세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : cs.surfaceVariant.withOpacity(.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withOpacity(.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 목록
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyResult(onClear: () {
              _search.clear();
              setState(() {});
            })
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                // 원본 인덱스를 찾아 펼침 상태 유지
                final item = _filtered[i];
                final originalIndex = _items.indexOf(item);
                final isOpen = _expanded.contains(originalIndex);

                return Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant.withOpacity(.5)),
                  ),
                  child: Theme(
                    // ExpansionTile 좌우 패딩 줄이기
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: isOpen,
                      onExpansionChanged: (v) {
                        setState(() {
                          if (v) {
                            _expanded.add(originalIndex);
                          } else {
                            _expanded.remove(originalIndex);
                          }
                        });
                      },
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      leading: const _QAIcon(q: true),
                      title: Text(item.q, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _QAIcon(q: false),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.a,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QAIcon extends StatelessWidget {
  final bool q; // true=Q, false=A
  const _QAIcon({required this.q});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = q ? cs.primary.withOpacity(.08) : Colors.green.withOpacity(.10);
    final fg = q ? cs.primary : Colors.green[700];
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(q ? 'Q' : 'A', style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyResult({required this.onClear});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: cs.outline),
          const SizedBox(height: 8),
          const Text('검색 결과가 없습니다.'),
          TextButton(onPressed: onClear, child: const Text('검색어 지우기')),
        ],
      ),
    );
  }
}