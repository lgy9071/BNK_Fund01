import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <- 햅틱
import 'fund_detail_screen.dart';

/// 색/헬퍼
const tossBlue  = Color(0xFF0064FF);
const tossBlack = Color(0xFF202632);
Color pastel(Color c) => c.withOpacity(.12);

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
  void run(void Function() f) { _t?.cancel(); _t = Timer(delay, f); }
  void dispose() => _t?.cancel();
}

class FundJoinScreen extends StatefulWidget {
  const FundJoinScreen({super.key});
  @override
  State<FundJoinScreen> createState() => _FundJoinScreenState();
}

class _FundJoinScreenState extends State<FundJoinScreen> {
  final _searchCtrl = TextEditingController();
  final _debouncer  = _Debouncer(const Duration(milliseconds: 300));
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
      return1m: 6.69, return3m: 33.40, return12m: 28.01,
      badges: ['BNK전용', '낮은위험(2등급)'],
    ),
    JoinFund(
      id: 2,
      name: '삼성달러표시단기채권자투자신탁 UH[채권]',
      subName: 'Class A',
      type: '해외 주식',
      launchedAt: DateTime(2016, 5, 18),
      return1m: 2.08, return3m: -1.02, return12m: -1.13,
      badges: ['해외', '채권형'],
    ),
    JoinFund(
      id: 3,
      name: '한국성장주식 A',
      subName: 'Class A',
      type: '혼합형',
      launchedAt: DateTime(2019, 1, 10),
      return1m: 1.50, return3m: 7.20, return12m: 12.30,
      badges: ['인기', '국내'],
    ),
  ];

  // 탭별 칩
  final _typeChips   = ['전체', '국내 주식', '해외 주식', '혼합형'];
  final _themeChips  = ['전체', '인기', '채권형', 'BNK전용', '낮은위험(2등급)'];
  final _globalChips = ['전체', '운용사 A', '운용사 B', '운용사 C'];

  String? _selectedType;
  String? _selectedTheme;
  String? _selectedGlobal;

  int _tabIndex = 0;

  List<JoinFund> get _filtered {
    final q = _searchCtrl.text.trim();
    List<JoinFund> base = _tabIndex == 0
        ? _filterByType(_allFunds)
        : _tabIndex == 1
        ? _filterByBadge(_allFunds)
        : _filterByGlobal(_allFunds);
    if (q.isNotEmpty) {
      base = base.where((f) => f.name.contains(q) || f.subName.contains(q)).toList();
    }
    return base;
  }

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
    // 예시: type으로 대충 매칭
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
      case '국내 주식': return Colors.blue.withOpacity(0.15);
      case '해외 주식': return Colors.green.withOpacity(0.15);
      case '혼합형'  :   return Colors.orange.withOpacity(0.15);
      default:           return Colors.grey.withOpacity(0.15);
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
            preferredSize: const Size.fromHeight(162),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // 🔍 검색 박스: 투명 + 파란 테두리
                  Card(
                    color: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => _debouncer.run(() => setState(() {})),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          hintText: '펀드를 검색해보세요',
                          suffixIcon: const Icon(Icons.search, color: tossBlue),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: tossBlue, width: 1.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: tossBlue, width: 1.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TabBar(
                    labelColor: tossBlue,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: tossBlue,
                    indicatorWeight: 2,
                    onTap: (idx) => setState(() => _tabIndex = idx),
                    tabs: const [
                      Tab(text: '유형별'),
                      Tab(text: '테마별'),
                      Tab(text: '글로벌제휴별'),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildListView(
              chips: _typeChips,
              icons: const {
                '전체': Icons.all_inclusive,
                '국내 주식': Icons.flag,
                '해외 주식': Icons.public,
                '혼합형': Icons.category,
              },
              selectedChip: _selectedType,
              onChipSelected: (v) => setState(() => _selectedType = v),
              list: funds,
            ),
            _buildListView(
              chips: _themeChips,
              icons: const {
                '전체': Icons.all_inclusive,
                '인기': Icons.whatshot,
                '채권형': Icons.request_quote,
                'BNK전용': Icons.star,
                '낮은위험(2등급)': Icons.shield_moon_outlined,
              },
              selectedChip: _selectedTheme,
              onChipSelected: (v) => setState(() => _selectedTheme = v),
              list: funds,
            ),
            _buildListView(
              chips: _globalChips,
              icons: const {
                '전체': Icons.all_inclusive,
                '운용사 A': Icons.apartment,
                '운용사 B': Icons.business,
                '운용사 C': Icons.domain,
              },
              selectedChip: _selectedGlobal,
              onChipSelected: (v) => setState(() => _selectedGlobal = v),
              list: funds,
            ),
          ],
        ),
      ),
    );
  }

  /// 칩 + 리스트 (모노톤 + 액션 강화: 등장/눌림/플래시/스와이프)
  Widget _buildListView({
    required List<String> chips,
    required Map<String, IconData> icons,
    required String? selectedChip,
    required void Function(String?) onChipSelected,
    required List<JoinFund> list,
  }) {
    return Column(
      children: [
        // 칩 박스
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final t = chips[i];
                  final sel = selectedChip == t;
                  return ChoiceChip(
                    selected: sel,
                    onSelected: (y) => onChipSelected(y ? t : null),
                    selectedColor: pastel(tossBlue),
                    backgroundColor: Colors.white,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[t], size: 18, color: sel ? tossBlue : Colors.black87),
                        const SizedBox(width: 6),
                        Text(t, style: TextStyle(color: sel ? tossBlue : Colors.black87)),
                      ],
                    ),
                    side: BorderSide(color: sel ? tossBlue : Colors.black26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: chips.length,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 목록
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final f = list[i];
                final sel = _compare.contains(f.id);

                // 각 아이템용 탭 플래시 키
                final flashKey = GlobalKey<_TapFlashState>();

                // 카드 본문
                final innerCard = ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        flashKey.currentState?.flash();
                        await Future.delayed(const Duration(milliseconds: 90));
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FundDetailScreen(fund: f)),
                        );
                      },
                      child: Stack(
                        children: [
                          // 연한 좌측 포커스 스트립 (3px)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(width: 3, color: tossBlue.withOpacity(.16)),
                            ),
                          ),
                          // 콘텐츠
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상단: 유형 칩 + 비교
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _typeColor(f.type),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(f.type, style: const TextStyle(fontSize: 10)),
                                    ),
                                    const Spacer(),
                                    OutlinedButton(
                                      onPressed: () => _toggleCompare(f.id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: sel ? Colors.white : tossBlue,
                                        backgroundColor: sel ? tossBlue : Colors.transparent,
                                        side: BorderSide(color: sel ? Colors.transparent : tossBlue),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      child: Text(sel ? '비교 중' : '비교하기'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // 제목/서브
                                Text(
                                  f.name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  f.subName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // 기본 정보 + 수익률
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('설정일 ${_fmtDate(f.launchedAt)}', style: const TextStyle(fontSize: 12)),
                                        const SizedBox(height: 2),
                                        const Text('기준가 1,000원', style: TextStyle(fontSize: 12)),
                                        const SizedBox(height: 2),
                                        const Text('순자산 3억', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('1개월 수익률', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('${f.return1m.toStringAsFixed(2)}%', style: _ret(f.return1m)),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 뱃지
                                Wrap(
                                  spacing: 4,
                                  children: f.badges.map((b) {
                                    return Chip(
                                      label: Text(b, style: const TextStyle(fontSize: 11)),
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(.3),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          // 탭 순간 플래시 오버레이
                          _TapFlash(key: flashKey),
                        ],
                      ),
                    ),
                  ),
                );

                // 등장(슬라이드+페이드) + 눌림(press) + 스와이프 비교
                return _StaggeredSlideFade(
                  index: i,
                  child: _Pressable(
                    child: Dismissible(
                      key: ValueKey('cmp-${f.id}'),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        color: tossBlue.withOpacity(.08),
                        child: const Icon(Icons.compare_arrows, color: tossBlue),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: tossBlue.withOpacity(.08),
                        child: const Icon(Icons.compare_arrows, color: tossBlue),
                      ),
                      confirmDismiss: (_) async {
                        _toggleCompare(f.id);
                        HapticFeedback.selectionClick();
                        return false; // 실제 삭제되지 않도록
                      },
                      child: innerCard,
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

/// ▼ 등장 애니메이션: 아래서 20px 슬라이드 + 페이드
class _StaggeredSlideFade extends StatelessWidget {
  final int index;
  final Widget child;
  const _StaggeredSlideFade({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final dur = Duration(milliseconds: 420 + (index % 12) * 40);
    return TweenAnimationBuilder<double>(
      duration: dur,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, _) => Transform.translate(
        offset: Offset(0, (1 - t) * 20),
        child: Opacity(opacity: t, child: child),
      ),
    );
  }
}

/// ▼ 눌림 인터랙션: 0.98 스케일 + 그림자 살짝 변경
class _Pressable extends StatefulWidget {
  final Widget child;
  const _Pressable({required this.child});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp:   (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        scale: _down ? 0.98 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          decoration: BoxDecoration(
            boxShadow: _down
                ? [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2))]
                : [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// ▼ 탭 순간 플래시(흰색이 살짝 번쩍)
class _TapFlash extends StatefulWidget {
  const _TapFlash({super.key});
  @override
  State<_TapFlash> createState() => _TapFlashState();
}

class _TapFlashState extends State<_TapFlash> {
  double _opacity = 0;
  Future<void> flash() async {
    setState(() => _opacity = .12);
    await Future.delayed(const Duration(milliseconds: 90));
    if (mounted) setState(() => _opacity = 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _opacity,
        child: Container(color: Colors.white),
      ),
    );
  }
}