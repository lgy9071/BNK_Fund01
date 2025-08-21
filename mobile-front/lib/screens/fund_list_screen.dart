import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_front/core/services/fund_service.dart';
import 'package:mobile_front/models/api_response.dart';
import 'package:mobile_front/models/fund_list_item.dart';

import 'fund_detail_screen.dart';

/// 브랜드 컬러
const tossBlue = Color(0xFF0064FF);
Color pastel(Color base) => Color.lerp(Colors.white, base, 0.12)!;

/// UI용 리스트 아이템
class JoinFund {
  final int id;
  final String fundId;
  final String name;
  final String subName;
  final String type;       // 주식형/채권형/혼합형 등
  final DateTime? launchedAt;
  final double return1m, return3m, return12m;
  final List<String> badges; // 위험(2등급), 투자신탁 등

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

// 타입 표준화: 원본 표기를 칩 텍스트(전체/주식형/채권형/혼합형)에 맞춤
String _canonByText(String? s) {
  final t = (s ?? '').replaceAll(RegExp(r'\s'), '').toLowerCase();
  if (t.isEmpty) return '기타';
  if (t.contains('주식') || t.contains('equity') || t.contains('stock')) return '주식형';
  if (t.contains('채권') || t.contains('bond') || t.contains('fixed'))   return '채권형';
  if (t.contains('혼합') || t.contains('복합') || t.contains('balanced') || t.contains('mix') || t.contains('hybrid'))
    return '혼합형';
  return '기타';
}

// ② FundListItem 전체를 보고 최종 타입 결정
String _canonTypeFromAny(FundListItem f) {
  final a = _canonByText(f.fundType);
  if (a != '기타') return a;
  final b = _canonByText(f.fundDivision);
  if (b != '기타') return b;
  final c = _canonByText(f.fundName);
  if (c != '기타') return c;
  return '기타';
}

/// DTO → UI 모델
JoinFund _joinFundFromDto(FundListItem f) {
  DateTime? _parse(String? s) {
    if (s == null || s.isEmpty) return null;
    final p = s.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }
  return JoinFund(
    id: f.fundId.hashCode,
    fundId: f.fundId,
    name: f.fundName,
    subName: f.managementCompany ?? '',
    type: _canonTypeFromAny(f),
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
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}' ;

/// 검색 디바운서
class _Debouncer {
  _Debouncer(this.delay);
  final Duration delay;
  Timer? _t;
  void run(void Function() f) { _t?.cancel(); _t = Timer(delay, f); }
  void dispose() => _t?.cancel();
}

/// 배지 중 '위험'이 아닌 것(투자신탁 등) 우선, 없으면 type
String _divisionOf(JoinFund f) {
  final nonRisk = f.badges.firstWhere((b) => !b.startsWith('위험'), orElse: () => '');
  return nonRisk.isNotEmpty ? nonRisk : f.type;
}

/// 슬라이드 + 페이드(위→아래로 살짝)
class __SlideFade extends StatelessWidget {
  final Animation<double> t;       // 0~1
  final Widget child;
  final double dy;                 // 시작 Y오프셋(아래가 +)
  const __SlideFade({super.key, required this.t, required this.child, this.dy = 0.08});
  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(begin: Offset(0, -dy), end: Offset.zero)
        .animate(CurvedAnimation(parent: t, curve: Curves.easeOutCubic));
    final fade  = CurvedAnimation(parent: t, curve: Curves.easeOut);
    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
  }
}

class FundListScreen extends StatefulWidget {
  const FundListScreen({super.key});
  @override
  State<FundListScreen> createState() => _FundListScreenState();
}

class _FundListScreenState extends State<FundListScreen> with TickerProviderStateMixin {
  final _svc = FundService();
  final _searchCtrl = TextEditingController();
  final _debouncer = _Debouncer(const Duration(milliseconds: 350));

  // 새로고침 더 가볍게 트리거
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  bool _autoRefreshing = false;
  double _pullAccum = 0.0; // 살짝 당긴 거리 누적

  // 컨트롤러는 내부 ListView에 연결 (NestedScrollView엔 연결하지 않음)
  final _scroll = ScrollController();
  bool _showHeader = true; // 헤더 노출 제어용 플래그

  List<JoinFund> _items = [];
  PaginationInfo? _page;
  bool _loading = false;
  bool _initialized = false;

  // 유형 칩 상태
  String _selType = '전체';
  static const _typeChips = ['전체', '주식형', '채권형', '혼합형'];
  final chipIconPaths = <String, String>{
    '전체'  : 'assets/icons/ic_all.png',
    '주식형': 'assets/icons/ic_equity.png',
    '채권형': 'assets/icons/ic_bond.png',
    '혼합형': 'assets/icons/ic_mix.png',
  };

  // 헤더 애니메이션(제목 → 검색 → 칩)
  late final AnimationController _hdrCtl;
  late final Animation<double> _tTitle, _tSearch, _tChips;

  // 리스트 스태거 애니메이션(첫 페이지 진입 시 카드가 차례대로)
  late final AnimationController _listCtl;
  int _firstPageCount = 0;
  bool _animateFirstPage = true;

  @override
  void initState() {
    super.initState();

    // 헤더 스태거
    _hdrCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _tTitle  = CurvedAnimation(parent: _hdrCtl, curve: const Interval(0.00, 0.45, curve: Curves.easeOut));
    _tSearch = CurvedAnimation(parent: _hdrCtl, curve: const Interval(0.18, 0.75, curve: Curves.easeOut));
    _tChips  = CurvedAnimation(parent: _hdrCtl, curve: const Interval(0.45, 1.00, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _hdrCtl.forward());

    // 리스트 스태거
    _listCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _load(page: 0);

    // 무한 스크롤
    _scroll.addListener(() {
      // 목록 끝쪽 페이징
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
        if (!_loading && (_page?.hasNext ?? false)) _load(page: (_page!.page + 1));
      }

      // 헤더 보임/숨김 토글 (offset이 거의 0일 때만 보이도록)
      final shouldShow = _scroll.hasClients ? _scroll.offset < 24.0 : true;
      if (shouldShow != _showHeader && mounted) {
        setState(() => _showHeader = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debouncer.dispose();
    _scroll.dispose();
    _hdrCtl.dispose();
    _listCtl.dispose();
    super.dispose();
  }

  Future<void> _load({required int page}) async {
    setState(() => _loading = true);
    try {
      final res = await _svc.getFunds(
        keyword: _searchCtrl.text.trim(),
        page: page,
        size: 10,
        fundType: null,
        riskLevel: null,
        company: null,
      );

      var list = (res.data ?? []).map(_joinFundFromDto).toList();
      if (_selType != '전체') list = list.where((e) => e.type == _selType).toList();

      if (page == 0) {
        _items = list;
        _firstPageCount = _items.length;
        _animateFirstPage = true;
        _listCtl.reset();
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _listCtl.forward(); });
      } else {
        _items.addAll(list);
        _animateFirstPage = false; // 페이지 추가분은 애니메이션 없이
      }
      _page = res.pagination;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('목록 로드 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialized = true;
        });
      }
    }
  }

  TextStyle _ret(double v) => TextStyle(
    fontSize: 20,
    color: v >= 0 ? Colors.red : Colors.blue,
    fontWeight: FontWeight.w800,
  );

  Color _chipBg(String t) {
    if (t.startsWith('위험')) return pastel(Colors.orange);
    if (t.contains('주식')) return pastel(tossBlue);
    if (t.contains('채권')) return pastel(Colors.green);
    if (t.contains('혼합')) return pastel(Colors.purple);
    return pastel(Colors.grey);
  }

  Widget _badgeChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: _chipBg(text), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _buildHeader(double headerH) {
    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: headerH,
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1) 제목
                        __SlideFade(
                          t: _tTitle,
                          child: const Text(
                            '펀드 찾기',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 2) 검색바 (폭 축소 & 높이 얇게)
                        __SlideFade(
                          t: _tSearch,
                          child: Align(
                            alignment: Alignment.center,
                            child: FractionallySizedBox(
                              widthFactor: 0.86,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => _debouncer.run(() => _load(page: 0)),
                                onSubmitted: (_) => _load(page: 0),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: '펀드를 검색해보세요',
                                  prefixIcon: const Icon(Icons.search, color: tossBlue),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: tossBlue, width: 1.2),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: tossBlue, width: 1.6),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // 3) 유형 칩 (라벨 없이 칩만)
                        __SlideFade(
                          t: _tChips,
                          child: SizedBox(
                            height: 44,
                            child: _ChipsRow(
                              items: _typeChips,
                              selected: _selType,
                              onSelected: (v) { setState(() => _selType = v); _load(page: 0); },
                              leadingBuilder: (t, sel) {
                                final path = chipIconPaths[t];
                                if (path == null) {
                                  return Icon(Icons.category, size: 16, color: sel ? tossBlue : Colors.black87);
                                }
                                return Image.asset(
                                  path, width: 16, height: 16, filterQuality: FilterQuality.medium,
                                  // color: sel ? tossBlue : Colors.black87,
                                  // colorBlendMode: BlendMode.srcIn,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 상단 1/3, 목록 2/3 비율
    final screenH = MediaQuery.of(context).size.height;
    final headerH = (screenH * 0.33).clamp(220.0, 380.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, _) {
          final screenH = MediaQuery.of(context).size.height;
          final headerH = (screenH * 0.33).clamp(220.0, 380.0);

          return AnimatedBuilder(
            animation: _scroll,
            builder: (context, __) {
              final offset = _scroll.hasClients ? _scroll.offset : 0.0;
              // 헤더가 위로 이동하는 거리(0 ~ headerH)
              final y = offset.clamp(0.0, headerH);

              // 헤더 노출 비율 t: 1(완전 노출) ~ 0(완전 숨김)
              final t = (1.0 - (y / headerH)).clamp(0.0, 1.0);

              // 첫 카드 위 파스텔 배경 노출 여백(최대 20 → 0)
              const double kRevealGapMax = 15.0;
              final revealGap = kRevealGapMax * t;

              // 헤더가 올라간 만큼 + 추가 여백 + 기본여백(8)
              const double kHeaderBottomPad = 8.0;   // 필요하면 0~12 안에서 조절
              final topPad = kHeaderBottomPad + (headerH - y) + revealGap;

              // 스피너를 "헤더 바로 아래"에 그리도록 위치 계산
              final double spinnerY = (topPad - 16).clamp(16.0, topPad).toDouble();

              return Stack(
                children: [
                  // ① 리스트(항상 전체 화면)
                  Positioned.fill(
                    child: (!_initialized && _loading)
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                      key: _refreshKey,
                      onRefresh: () => _load(page: 0),
                      // 헤더 아래에서 스피너가 보이도록 위치 조정
                      edgeOffset: topPad,
                      displacement: (topPad - 8).clamp(8.0, topPad).toDouble(),
                      color: tossBlue,
                      backgroundColor: Colors.white,
                      strokeWidth: 2.6,
                      notificationPredicate: (n) => n.depth == 0,
                      child: Container(
                        color: pastel(tossBlue),
                        child: NotificationListener<ScrollNotification>(
                          // 살짝만 내려도 새로고침되도록: 누적 풀다운 거리로 강제 show()
                          onNotification: (n) {
                            final atTop = n.metrics.extentBefore == 0;

                            if (atTop) {
                              if (n is OverscrollNotification && n.overscroll < 0) {
                                _pullAccum += -n.overscroll; // 위쪽으로 당김 누적
                              } else if (n is ScrollUpdateNotification) {
                                final d = n.scrollDelta ?? 0;
                                if (d < 0) _pullAccum += -d;
                              }

                              // 임계치(px) 넘으면 강제 새로고침
                              if (!_autoRefreshing && !_loading && _pullAccum > 8) {
                                _autoRefreshing = true;
                                _refreshKey.currentState?.show();
                              }
                            }

                            // 드래그가 끝나면 누적 초기화
                            if (n is ScrollEndNotification) {
                              _pullAccum = 0.0;
                              _autoRefreshing = false;
                            }
                            return false; // 기본 동작 유지
                          },
                          child: ListView.separated(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16, topPad, 16, 16),
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
                                if (!(_page?.hasNext ?? false)) return const SizedBox(height: 24);
                                return const SizedBox.shrink();
                              }

                              final f = _items[i];

                              Animation<double> it;
                              if (_animateFirstPage && i < _firstPageCount) {
                                final start = (i * 0.06).clamp(0.0, 0.9);
                                final end = (start + 0.4).clamp(0.0, 1.0);
                                it = CurvedAnimation(parent: _listCtl, curve: Interval(start, end, curve: Curves.easeOut));
                              } else {
                                it = const AlwaysStoppedAnimation(1.0);
                              }

                              final card = _Pressable(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Material(
                                    color: Colors.white,
                                    surfaceTintColor: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
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
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: tossBlue.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    _divisionOf(f),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: tossBlue,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                if (f.launchedAt != null)
                                                  Text('설정일 ${_fmtDate(f.launchedAt!)}', style: const TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
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
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: [
                                                    if (f.badges.any((b) => b.startsWith('위험')))
                                                      _badgeChip(f.badges.firstWhere((b) => b.startsWith('위험'))),
                                                    _badgeChip(f.type),
                                                  ],
                                                ),
                                                const Spacer(),
                                                const Text('1개월 수익률', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                const SizedBox(width: 8),
                                                Text('${f.return1m.toStringAsFixed(2)}%', style: _ret(f.return1m)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              return __SlideFade(t: it, dy: .06, child: card);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),


                  // ② 헤더(흰 배경) — 스크롤에 맞춰 "그냥 위로" 올라가게만
                  Positioned(
                    top: -y,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: y >= headerH - 1,
                      child: Container(
                        color: Colors.white,
                        child: _buildHeader(headerH),
                      ),
                    ),
                  ),
                ],
              );
            },
          );

        },
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
                ? [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: Offset(0, 2))]
                : [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: Offset(0, 6))],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 칩 공용 위젯
class _ChipsRow extends StatelessWidget {
  final List<String> items;
  final String selected;
  final void Function(String) onSelected;

  // 항목별 왼쪽 아이콘(위젯) 커스텀 빌더
  final Widget Function(String item, bool selected)? leadingBuilder;

  // (옵션) 기본 아이콘 - leadingBuilder가 없을 때만 사용
  final IconData? icon;

  const _ChipsRow({
    required this.items,
    required this.selected,
    required this.onSelected,
    this.leadingBuilder,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, i) {
        final t = items[i];
        final sel = selected == t;

        final Widget leading = leadingBuilder != null
            ? leadingBuilder!(t, sel)
            : Icon(icon ?? Icons.category, size: 16, color: sel ? tossBlue : Colors.black87);

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 6),
              Text(t),
            ],
          ),
          selected: sel,
          onSelected: (_) => onSelected(t),
          selectedColor: tossBlue.withOpacity(.12),
          backgroundColor: Colors.white,
          side: BorderSide(color: sel ? tossBlue : Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: items.length,
    );
  }
}