import 'dart:async';
import 'package:flutter/material.dart';

/// 데모용 펀드 모델
class JoinFund {
  final int id;
  final String name;
  final String subName; // 클래스/종류 등
  final String type; // 국내 주식/해외 주식/혼합형 등
  final DateTime launchedAt;
  final double return1m;
  final double return3m;
  final double return12m;
  final List<String> badges; // 예: ['BNK전용', '낮은위험(2등급)']

  JoinFund({
    required this.id,
    required this.name,
    required this.subName,
    required this.type,
    required this.launchedAt,
    required this.return1m,
    required this.return3m,
    required this.return12m,
    required this.badges,
  });
}

/// 검색 디바운서
class _Debouncer {
  _Debouncer(this.delay);
  final Duration delay;
  Timer? _t;
  void run(void Function() f) {
    _t?.cancel();
    _t = Timer(delay, f);
  }
  void dispose() => _t?.cancel();
}

/// 펀드 가입 화면
class FundJoinScreen extends StatefulWidget {
  const FundJoinScreen({super.key});

  @override
  State<FundJoinScreen> createState() => _FundJoinScreenState();
}

class _FundJoinScreenState extends State<FundJoinScreen> {
  // 색
  static const tossBlue = Color(0xFF0064FF);
  static const tossGray = Color(0xFF202632);

  // ▼ ① 비교 선택 상태 추가
    /// 선택된 펀드 ID를 저장 (최대 2개)
    final Set<int> _compare = {};

    /// 비교 토글 (2개 초과시 스낵바)
    void _toggleCompare(int id) {
        if (_compare.contains(id)) {
          _compare.remove(id);
        } else {
          if (_compare.length >= 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('비교는 최대 2개까지만 가능합니다.')),
            );
            return;
          }
          _compare.add(id);
        }
        setState(() {});
      }

  // 데이터 (데모)
  final List<JoinFund> _allFunds = [
    JoinFund(
      id: 1,
      name: 'BNK이기는증권투자신탁(주식)',
      subName: 'Class C-P2e',
      type: '국내 주식',
      launchedAt: DateTime(2018, 2, 5),
      return1m: 6.69,
      return3m: 33.40,
      return12m: 28.01,
      badges: ['BNK전용', '낮은위험(2등급)'],
    ),
    JoinFund(
      id: 2,
      name: '삼성달러표시단기채권증권자투자신탁 UH[채권]_Cp',
      subName: 'Class A',
      type: '해외 주식',
      launchedAt: DateTime(2016, 5, 18),
      return1m: 2.08,
      return3m: -1.02,
      return12m: -1.13,
      badges: ['해외', '채권형'],
    ),
    JoinFund(
      id: 3,
      name: '한국성장주식 A',
      subName: 'Class A',
      type: '국내 주식',
      launchedAt: DateTime(2019, 1, 10),
      return1m: 1.5,
      return3m: 7.2,
      return12m: 12.3,
      badges: ['인기', '국내'],
    ),
    JoinFund(
      id: 4,
      name: '글로벌채권 인덱스',
      subName: 'Class I',
      type: '혼합형',
      launchedAt: DateTime(2020, 3, 1),
      return1m: -0.8,
      return3m: 2.3,
      return12m: 5.7,
      badges: ['인덱스', '채권'],
    ),
  ];

  // 상태
  final _searchCtrl = TextEditingController();
  final _debouncer = _Debouncer(const Duration(milliseconds: 300));

  // 드롭다운(유형/수익률/정렬) 선택값
  String _category = '전체';
  String _returnBase = '3개월'; // 수익률 기준
  String _sort = '최신순';

  // 토픽 필터(칩)
  final List<String> _topicChips = ['국내 주식', '해외 주식', '혼합형'];
  String? _selectedTopic;

  List<JoinFund> get _filtered {
    String q = _searchCtrl.text.trim();
    List<JoinFund> list = _allFunds.where((f) {
      if (_selectedTopic != null && f.type != _selectedTopic) return false;
      if (_category != '전체' && f.type != _category) return false;
      if (q.isNotEmpty) {
        return f.name.contains(q) || f.subName.contains(q);
      }
      return true;
    }).toList();

    // 정렬
    if (_sort == '최신순') {
      list.sort((a, b) => b.launchedAt.compareTo(a.launchedAt));
    } else if (_sort == '수익률 높은순') {
      double pick(JoinFund f) => _returnBase == '1개월'
          ? f.return1m
          : _returnBase == '3개월'
          ? f.return3m
          : f.return12m;
      list.sort((b, a) => pick(a).compareTo(pick(b)));
    } else if (_sort == '수익률 낮은순') {
      double pick(JoinFund f) => _returnBase == '1개월'
          ? f.return1m
          : _returnBase == '3개월'
          ? f.return3m
          : f.return12m;
      list.sort((a, b) => pick(a).compareTo(pick(b)));
    }

    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _showBottomSelect({
    required String title,
    required List<String> options,
    required String current,
    required void Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          ...options.map((opt) => ListTile(
            title: Text(opt),
            trailing: opt == current
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              Navigator.pop(ctx);
              onSelected(opt);
            },
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('펀드 가입'),
      ),
      body: CustomScrollView(
        slivers: [
          // ── 상단 검색 영역 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 검색
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _debouncer.run(() => setState(() {})),
                    decoration: InputDecoration(
                      hintText: '펀드를 검색해보세요',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: cs.outlineVariant.withOpacity(.6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: tossBlue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 유형 / 수익률 / 정렬 → Wrap으로 변환 (화면 깨짐 방지)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterPill(
                        label: '유형',
                        value: _category,
                        onTap: () => _showBottomSelect(
                          title: '유형',
                          options: const ['전체', '국내 주식', '해외 주식', '혼합형'],
                          current: _category,
                          onSelected: (v) => setState(() => _category = v),
                        ),
                      ),
                      _FilterPill(
                        label: '수익률',
                        value: _returnBase,
                        onTap: () => _showBottomSelect(
                          title: '수익률 기준',
                          options: const ['1개월', '3개월', '12개월'],
                          current: _returnBase,
                          onSelected: (v) => setState(() => _returnBase = v),
                        ),
                      ),
                      _FilterPill(
                        label: '정렬',
                        value: _sort,
                        onTap: () => _showBottomSelect(
                          title: '정렬',
                          options: const ['최신순', '수익률 높은순', '수익률 낮은순'],
                          current: _sort,
                          onSelected: (v) => setState(() => _sort = v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 토픽 칩
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('전체'),
                          selected: _selectedTopic == null,
                          onSelected: (_) => setState(() => _selectedTopic = null),
                        ),
                        const SizedBox(width: 8),
                        ..._topicChips.map((t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t),
                            selected: _selectedTopic == t,
                            onSelected: (_) =>
                                setState(() => _selectedTopic = t),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 결과 개요
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                '총 ${_filtered.length}개 펀드를 조회했습니다.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),

          // ── 리스트: 2열 그리드 ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final f = _filtered[i];
                  final selected = _compare.contains(f.id);
                  return _FundTile(
                    fund: f,
                    isCompared: selected,
                    onToggleCompare: () {
                      setState(() {
                        selected ? _compare.remove(f.id) : _compare.add(f.id);
                      });
                    },
                    onOpenDetail: () {
                      // TODO: 상세 페이지 라우팅
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('상세 이동: ${f.name}')));
                    },
                  );
                },
                childCount: _filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
      // 비교 버튼 (선택 시 표시)
      bottomNavigationBar: _compare.isEmpty
          ? null
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: () {
              // TODO: 비교 화면 이동
            },
            child: Text('선택한 ${_compare.length}개 비교하기'),
          ),
        ),
      ),
    );
  }
}

/// 상단 필터용 Pill 버튼 (Wrap에서 사용)
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label • $value',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      ),
    );
  }
}

/// 2열 그리드에서 쓰는 간단 타일 카드
class _FundTile extends StatelessWidget {
  const _FundTile({
    required this.fund,
    required this.onOpenDetail,
    required this.onToggleCompare,
    required this.isCompared,
  });

  final JoinFund fund;
  final VoidCallback onOpenDetail;
  final VoidCallback onToggleCompare;
  final bool isCompared;

  static const tossBlue = Color(0xFF0064FF);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    TextStyle ret(double v) => TextStyle(
      color: v >= 0 ? Colors.red : Colors.blue,
      fontWeight: FontWeight.w800,
    );
    String fmt(double v) => '${v.toStringAsFixed(2)}%';

    return Card(
      elevation: .6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenDetail, // ← 카드 전체 탭 시 상세 이동
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 (2줄까지)
              Text(
                fund.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                fund.subName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 6),

              // 뱃지 (최대 2개만 노출)
              Wrap(
                spacing: 4,
                runSpacing: -6,
                children: fund.badges.take(2).map((b) {
                  return Chip(
                    label: Text(b, style: const TextStyle(fontSize: 11)),
                    side: BorderSide.none,
                    backgroundColor: cs.primaryContainer.withOpacity(.35),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),

            // 수익률을 세로로 한 줄씩 표시 (Column)
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('1M ${fmt(fund.return1m)}', style: ret(fund.return1m)),
                  const SizedBox(height: 4),
                Text('3M ${fmt(fund.return3m)}', style: ret(fund.return3m)),
                    const SizedBox(height: 4),
                    Text('12M ${fmt(fund.return12m)}', style: ret(fund.return12m)),
                  ],
              ),
              const Spacer(),

              // 우측 “비교하기”만 배치
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: onToggleCompare,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isCompared ? Colors.white : tossBlue,
                    backgroundColor:
                    isCompared ? tossBlue : Colors.transparent,
                    side: const BorderSide(color: tossBlue),
                    visualDensity: VisualDensity.compact,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: Text(isCompared ? '비교 중' : '비교하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}