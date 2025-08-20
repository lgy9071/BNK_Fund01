import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_front/core/services/fund_service.dart';
import 'package:mobile_front/models/api_response.dart';
import 'package:mobile_front/models/fund_list_item.dart';

import 'fund_detail_screen.dart';

/// 브랜드 컬러
const tossBlue = Color(0xFF0064FF);

/// UI용 리스트 아이템(기존 JoinFund 대체/확장)
class JoinFund {
  final int id;            // UI 식별용(int)
  final String fundId;     // 서버의 실제 ID(String)
  final String name;       // 펀드명
  final String subName;    // 운용사 등 서브텍스트
  final String type;       // 분류 표기(펀드 타입)
  final DateTime? launchedAt;
  final double return1m, return3m, return12m;
  final List<String> badges;

  JoinFund({
    required this.id,
    required this.fundId,
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

/// FundListItem → JoinFund 변환
JoinFund _joinFundFromDto(FundListItem f) {
  DateTime? _parse(String? s) {
    if (s == null || s.isEmpty) return null;
    final p = s.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  return JoinFund(
    id: f.fundId.hashCode,          // 화면용 ID(int)
    fundId: f.fundId,               // 서버 호출용 실제 ID(String)
    name: f.fundName,
    subName: f.managementCompany ?? '',
    type: f.fundType ?? '펀드',
    launchedAt: _parse(f.issueDate),
    return1m: f.return1m ?? 0,
    return3m: f.return3m ?? 0,
    return12m: f.return12m ?? 0,
    badges: [
      if (f.riskLevel != null) '위험(${f.riskLevel}등급)',
      if (f.fundDivision != null) f.fundDivision!,
    ],
  );
}

/// 날짜 포맷
String _fmtDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// 검색 디바운서
class _Debouncer {
  _Debouncer(this.delay);
  final Duration delay;
  Timer? _t;
  void run(void Function() f) { _t?.cancel(); _t = Timer(delay, f); }
  void dispose() => _t?.cancel();
}

class FundListScreen extends StatefulWidget {
  const FundListScreen({super.key});
  @override
  State<FundListScreen> createState() => _FundListScreenState();
}

class _FundListScreenState extends State<FundListScreen> {
  final _svc = FundService();
  final _searchCtrl = TextEditingController();
  final _debouncer = _Debouncer(const Duration(milliseconds: 350));
  final _scroll = ScrollController();

  List<JoinFund> _items = [];
  PaginationInfo? _page;
  bool _loading = false;
  bool _initialized = false;

  // ====== 필터 상태 ======
  int _tabIndex = 0;                 // 0: 유형별, 1: 추가
  String? _selType;                  // fundType
  int? _selRisk;                     // 1~5
  String? _selCompany;               // 운용사명
  static const _typeChips = ['전체', '주식형', '채권형', '혼합형'];
  static const _riskChips = ['전체', '1등급', '2등급', '3등급', '4등급', '5등급'];
  List<String> _companyChips = ['전체']; // 로드 후 동적 구성

  @override
  void initState() {
    super.initState();
    _load(page: 0);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
        if (!_loading && (_page?.hasNext ?? false)) {
          _load(page: (_page!.page + 1));
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debouncer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({required int page}) async {
    setState(() => _loading = true);
    try {
      final res = await _svc.getFunds(
        keyword: _searchCtrl.text.trim(),
        page: page,
        size: 10,
        fundType: _selType == null || _selType == '전체' ? null : _selType,
        riskLevel: _selRisk,
        company: _selCompany == null || _selCompany == '전체' ? null : _selCompany,
      );

      var list = (res.data ?? []).map(_joinFundFromDto).toList();

      // 서버가 일부 필터 미지원일 경우를 대비해 클라에서 한 번 더 보정
      list = _applyClientFilter(list);

      if (page == 0) {
        _items = list;

        // 운용사 칩 채우기(상위 12개)
        final s = <String>{};
        for (final it in _items) {
          if (it.subName.isNotEmpty) s.add(it.subName);
        }
        _companyChips = ['전체', ...s.take(12)];
      } else {
        _items.addAll(list);
      }
      _page = res.pagination;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목록 로드 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialized = true;
        });
      }
    }
  }

  List<JoinFund> _applyClientFilter(List<JoinFund> list) {
    var out = list;
    if (_selType != null && _selType != '전체') {
      out = out.where((e) => e.type == _selType).toList();
    }
    if (_selRisk != null) {
      out = out.where((e) {
        final m = RegExp(r'\((\d)\)').firstMatch(e.badges.join());
        final risk = m != null ? int.tryParse(m.group(1)!) : null;
        return risk == _selRisk;
      }).toList();
    }
    if (_selCompany != null && _selCompany != '전체') {
      out = out.where((e) => e.subName == _selCompany).toList();
    }
    return out;
  }

  TextStyle _ret(double v) => TextStyle(
    fontSize: 20,
    color: v >= 0 ? Colors.red : Colors.blue,
    fontWeight: FontWeight.w800,
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _tabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('펀드 찾기'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(160),
            child: Column(
              children: [
                // 검색창
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Card(
                    color: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => _debouncer.run(() => _load(page: 0)),
                        onSubmitted: (_) => _load(page: 0),
                        decoration: InputDecoration(
                          isDense: true,
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
                ),

                // 탭바
                TabBar(
                  labelColor: tossBlue,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: tossBlue,
                  onTap: (i) => setState(() => _tabIndex = i),
                  tabs: const [
                    Tab(text: '유형별'),
                    Tab(text: '추가'),
                  ],
                ),

                // 칩 영역
                SizedBox(
                  height: 56,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // 유형별
                      _ChipsRow(
                        items: _typeChips,
                        selected: _selType ?? '전체',
                        onSelected: (v) {
                          setState(() => _selType = v == '전체' ? null : v);
                          _load(page: 0);
                        },
                        icon: Icons.category,
                      ),
                      // 추가(위험등급 + 운용사)
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _ChipGroup(
                            label: '위험등급',
                            items: _riskChips,
                            selected: _selRisk?.toString() ?? '전체',
                            onSelected: (t) {
                              setState(() => _selRisk = t == '전체' ? null : int.parse(t[0]));
                              _load(page: 0);
                            },
                          ),
                          const SizedBox(width: 12),
                          _ChipGroup(
                            label: '운용사',
                            items: _companyChips,
                            selected: _selCompany ?? '전체',
                            onSelected: (t) {
                              setState(() => _selCompany = t == '전체' ? null : t);
                              _load(page: 0);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        body: !_initialized && _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: () => _load(page: 0),
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              if (i == _items.length) {
                if (_loading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!(_page?.hasNext ?? false)) {
                  return const SizedBox(height: 24);
                }
                return const SizedBox.shrink();
              }

              final f = _items[i];

              return _Pressable(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FundDetailScreen(
                              fundId: f.fundId,
                              title: f.name,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상단: 유형 칩
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tossBlue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(f.type, style: const TextStyle(fontSize: 10, color: tossBlue)),
                                ),
                                const Spacer(),
                                if (f.launchedAt != null)
                                  Text('설정일 ${_fmtDate(f.launchedAt!)}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // 제목/서브
                            Text(
                              f.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                            const SizedBox(height: 8),

                            // 수익률
                            Row(
                              children: [
                                const Text('1개월 수익률', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text('${f.return1m.toStringAsFixed(2)}%', style: _ret(f.return1m)),
                                const Spacer(),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 눌림 인터랙션(살짝 축소)
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
      onPointerUp: (_) => setState(() => _down = false),
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

// ───────────── 칩 공용 위젯
class _ChipsRow extends StatelessWidget {
  final List<String> items;
  final String selected;
  final void Function(String) onSelected;
  final IconData icon;
  const _ChipsRow({required this.items, required this.selected, required this.onSelected, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, i) {
        final t = items[i];
        final sel = selected == t || (selected == '전체' && t == '전체');
        return ChoiceChip(
          label: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: sel ? tossBlue : Colors.black87),
            const SizedBox(width: 6), Text(t),
          ]),
          selected: sel,
          onSelected: (_) => onSelected(t),
          selectedColor: tossBlue.withOpacity(.12),
          backgroundColor: Colors.white,
          side: BorderSide(color: sel ? tossBlue : Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: items.length,
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final String label;
  final List<String> items;
  final String selected;
  final void Function(String) onSelected;
  const _ChipGroup({required this.label, required this.items, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        ...items.map((t) {
          final sel = selected == t || (selected == '전체' && t == '전체');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t),
              selected: sel,
              onSelected: (_) => onSelected(t),
              selectedColor: tossBlue.withOpacity(.12),
              backgroundColor: Colors.white,
              side: BorderSide(color: sel ? tossBlue : Colors.black26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }),
      ],
    );
  }
}
