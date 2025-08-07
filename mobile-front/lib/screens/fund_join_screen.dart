import 'dart:async';
import 'package:flutter/material.dart';
import 'fund_detail_screen.dart';

/// 데모용 펀드 모델
class JoinFund {
  final int id;
  final String name;
  final String subName;
  final String type;
  final DateTime launchedAt;
  final double return1m, return3m, return12m;
  final List<String> badges;

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

const tossBlue = Color(0xFF0064FF);

class FundJoinScreen extends StatefulWidget {
  const FundJoinScreen({super.key});
  @override
  State<FundJoinScreen> createState() => _FundJoinScreenState();
}

class _FundJoinScreenState extends State<FundJoinScreen> {
  final _searchCtrl = TextEditingController();
  final _debouncer = _Debouncer(const Duration(milliseconds: 300));

  final Set<int> _compare = {};
  void _toggleCompare(int id) {
    setState(() {
      if (_compare.contains(id)) {
        _compare.remove(id);
      } else if (_compare.length < 2) {
        _compare.add(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비교는 최대 2개까지만 가능합니다.')),
        );
      }
    });
  }

  final List<JoinFund> _allFunds = [
    JoinFund(
      id: 1,
      name: 'BNK이기는증권투자신탁(주식) 매우 긴 이름도 잘립니다.',
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
      name: '삼성달러표시단기채권자투자신탁 UH[채권]',
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
      type: '혼합형',
      launchedAt: DateTime(2019, 1, 10),
      return1m: 1.50,
      return3m: 7.20,
      return12m: 12.30,
      badges: ['인기', '국내'],
    ),
    // … 필요 시 더 추가 …
  ];

  // 탭별 칩
  final _typeChips = ['전체', '국내 주식', '해외 주식', '혼합형'];
  final _themeChips = ['전체', '인기', '채권형', 'BNK전용', '낮은위험(2등급)'];
  final _globalChips = ['전체', '운용사 A', '운용사 B', '운용사 C'];

  String? _selectedType;
  String? _selectedTheme;
  String? _selectedGlobal;

  List<JoinFund> get _filtered {
    final q = _searchCtrl.text.trim();
    // filter by active tab
    List<JoinFund> base = _tabIndex == 0
        ? _filterByType(_allFunds)
        : _tabIndex == 1
        ? _filterByBadge(_allFunds)
        : _filterByGlobal(_allFunds);
    if (q.isNotEmpty) {
      base = base.where((f) {
        return f.name.contains(q) || f.subName.contains(q);
      }).toList();
    }
    return base;
  }

  int _tabIndex = 0;

  List<JoinFund> _filterByType(List<JoinFund> list) {
    if (_selectedType == null || _selectedType == '전체') return list;
    return list.where((f) => f.type == _selectedType).toList();
  }

  List<JoinFund> _filterByBadge(List<JoinFund> list) {
    if (_selectedTheme == null || _selectedTheme == '전체') return list;
    return list.where((f) => f.badges.contains(_selectedTheme)).toList();
  }

  List<JoinFund> _filterByGlobal(List<JoinFund> list) {
    if (_selectedGlobal == null || _selectedGlobal == '전체') return list;
    // 예시: type 필드로 필터링
    return list.where((f) => f.type == _selectedGlobal).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  TextStyle _ret(double v) => TextStyle(
    fontSize: 20,
    color: v >= 0 ? Colors.red : Colors.blue,
    fontWeight: FontWeight.w800,
  );

  Color _typeColor(String t) {
    switch (t) {
      case '국내 주식':
        return Colors.blue.withOpacity(0.15);
      case '해외 주식':
        return Colors.green.withOpacity(0.15);
      case '혼합형':
        return Colors.orange.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final funds = _filtered;
    return DefaultTabController(
      length: 3,
      initialIndex: _tabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('펀드 찾기'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // 검색창
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _debouncer.run(() => setState(() {})),
                    decoration: InputDecoration(
                      hintText: '펀드를 검색해보세요',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: const Icon(Icons.search, color: tossBlue),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: tossBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: tossBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 탭바
                  TabBar(
                    labelColor: tossBlue,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: tossBlue,
                    indicatorWeight: 2,
                    onTap: (idx) {
                      setState(() {
                        _tabIndex = idx;
                      });
                    },
                    tabs: const [
                      Tab(text: '유형별'),
                      Tab(text: '테마별'),
                      Tab(text: '글로벌제휴별'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildListView(_typeChips, _selectedType, (v) {
              setState(() => _selectedType = v);
            }, funds),
            _buildListView(_themeChips, _selectedTheme, (v) {
              setState(() => _selectedTheme = v);
            }, funds),
            _buildListView(_globalChips, _selectedGlobal, (v) {
              setState(() => _selectedGlobal = v);
            }, funds),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
      List<String> chips,
      String? selectedChip,
      void Function(String?) onChipSelected,
      List<JoinFund> list) {
    return Column(
      children: [
        // 칩 행
        SizedBox(
          height: 48,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((t) {
                final sel = selectedChip == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: sel,
                    onSelected: (y) => onChipSelected(y ? t : null),
                    selectedColor: tossBlue.withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        // 목록
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final f = list[i];
                final sel = _compare.contains(f.id);
                return Card(
                  elevation: .6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => FundDetailScreen(fund: f)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단: 유형 칩 + 비교하기 버튼
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _typeColor(f.type),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(f.type,
                                    style: const TextStyle(fontSize: 10)),
                              ),
                              const Spacer(),
                              OutlinedButton(
                                onPressed: () => _toggleCompare(f.id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                  sel ? Colors.white : tossBlue,
                                  backgroundColor:
                                  sel ? tossBlue : Colors.transparent,
                                  side: const BorderSide(color: tossBlue),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                ),
                                child:
                                Text(sel ? '비교 중' : '비교하기'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 제목
                          Text(f.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(f.subName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12)),
                          const SizedBox(height: 6),
                          // 설정일·기준가·순자산 + 1개월 수익률
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 왼쪽 정보
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '설정일 ${_fmtDate(f.launchedAt)}',
                                      style: const TextStyle(
                                          fontSize: 12)),
                                  const SizedBox(height: 2),
                                  const Text('기준가 1,000원',
                                      style: TextStyle(fontSize: 12)),
                                  const SizedBox(height: 2),
                                  const Text('순자산 3억',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              // 오른쪽 수익률
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  const Text('1개월 수익률',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${f.return1m.toStringAsFixed(2)}%',
                                    style: _ret(f.return1m),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 뱃지
                          Wrap(
                            spacing: 4,
                            children: f.badges
                                .map((b) => Chip(
                              label: Text(b,
                                  style: const TextStyle(
                                      fontSize: 11)),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(.3),
                              visualDensity:
                              VisualDensity.compact,
                              materialTapTargetSize:
                              MaterialTapTargetSize
                                  .shrinkWrap,
                            ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}