import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/core/services/fund_service.dart';
import 'package:mobile_front/core/services/user_service.dart';
import 'package:mobile_front/models/api_response.dart';
import 'package:mobile_front/models/compare_fund_view.dart';
import 'package:mobile_front/models/fund_list_item.dart';
import 'package:mobile_front/screens/ai_compare_screen.dart';
import 'package:mobile_front/screens/compare_sheets.dart';

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
  final String type; // 주식형/채권형/혼합형 등
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

// 타입 표준화
String _canonByText(String? s) {
  final t = (s ?? '').replaceAll(RegExp(r'\s'), '').toLowerCase();
  if (t.isEmpty) return '기타';
  if (t.contains('주식') || t.contains('equity') || t.contains('stock'))
    return '주식형';
  if (t.contains('채권') || t.contains('bond') || t.contains('fixed'))
    return '채권형';
  if (t.contains('혼합') ||
      t.contains('복합') ||
      t.contains('balanced') ||
      t.contains('mix') ||
      t.contains('hybrid'))
    return '혼합형';
  return '기타';
}

// FundListItem → 최종 타입
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
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

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

/// 배지 중 '위험'이 아닌 것(투자신탁 등) 우선, 없으면 type
String _divisionOf(JoinFund f) {
  final nonRisk = f.badges.firstWhere(
    (b) => !b.startsWith('위험'),
    orElse: () => '',
  );
  return nonRisk.isNotEmpty ? nonRisk : f.type;
}

/// 슬라이드 + 페이드(위→아래로 살짝)
class __SlideFade extends StatelessWidget {
  final Animation<double> t; // 0~1
  final Widget child;
  final double dy; // 시작 Y오프셋(아래가 +)
  const __SlideFade({
    super.key,
    required this.t,
    required this.child,
    this.dy = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: Offset(0, -dy),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: t, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: t, curve: Curves.easeOut);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class FundListScreen extends StatefulWidget {
  const FundListScreen({
    super.key,
    this.accessToken,
    this.userService,
    this.investTypeName,
  });

  final String? accessToken;
  final UserService? userService;
  final String? investTypeName;

  @override
  State<FundListScreen> createState() => _FundListScreenState();
}

class _FundListScreenState extends State<FundListScreen>
    with TickerProviderStateMixin {
  final _svc = FundService();
  final _searchCtrl = TextEditingController();
  final _debouncer = _Debouncer(const Duration(milliseconds: 350));
  final _searchFocus = FocusNode();

  bool _fabOpen = false; // ✅ FAB 메뉴 열림 상태

  // 새로고침
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  bool _autoRefreshing = false;
  double _pullAccum = 0.0; // 당긴 누적 거리
  bool _pulledEnough = false; // 임계 넘었는지
  DateTime? _lastRefreshAt; // 쿨다운 기준 시각

  // 감도/쿨다운 설정 (값을 키우면 덜 민감해짐)
  static const double kPullToRefreshThreshold = 48.0; // px
  static const Duration kRefreshCooldown = Duration(milliseconds: 800);

  // 컨트롤러는 내부 ListView에 연결
  final _scroll = ScrollController();
  bool _showHeader = true;

  List<JoinFund> _items = [];
  PaginationInfo? _page;
  bool _loading = false;
  bool _initialized = false;

  // 유형 칩 상태
  String _selType = '전체';
  static const _typeChips = ['전체', '주식형', '채권형', '혼합형'];
  final chipIconPaths = <String, String>{
    '전체': 'assets/icons/ic_all.png',
    '주식형': 'assets/icons/ic_equity.png',
    '채권형': 'assets/icons/ic_bond.png',
    '혼합형': 'assets/icons/ic_mix.png',
  };

  // 헤더 애니메이션(제목 → 검색 → 칩)
  late final AnimationController _hdrCtl;
  late final Animation<double> _tTitle, _tSearch, _tChips;

  // 리스트 스태거 애니메이션
  late final AnimationController _listCtl;
  int _firstPageCount = 0;
  bool _animateFirstPage = true;

  // 선택된 펀드들( fundId 기준 )
  final Set<String> _picked = {};

  //토글
  void _togglePick(String fundId) {
    final already = _picked.contains(fundId);
    if (!already && _picked.length >= 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최대 2개까지만 담을 수 있어요.')));
      return;
    }
    setState(() {
      if (already) {
        _picked.remove(fundId);
      } else {
        _picked.add(fundId);
      }
    });
  }

  bool _isPicked(String fundId) => _picked.contains(fundId);

  @override
  void initState() {
    debugPrint('FundListScreen token? => ${widget.accessToken}');
    super.initState();

    // 헤더 스태거
    _hdrCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _tTitle = CurvedAnimation(
      parent: _hdrCtl,
      curve: const Interval(0.00, 0.45, curve: Curves.easeOut),
    );
    _tSearch = CurvedAnimation(
      parent: _hdrCtl,
      curve: const Interval(0.18, 0.75, curve: Curves.easeOut),
    );
    _tChips = CurvedAnimation(
      parent: _hdrCtl,
      curve: const Interval(0.45, 1.00, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _hdrCtl.forward());

    // 리스트 스태거
    _listCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _load(page: 0);

    // 무한 스크롤
    _scroll.addListener(() {
      // 목록 끝쪽 페이징
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
        if (!_loading && (_page?.hasNext ?? false))
          _load(page: (_page!.page + 1));
      }

      // 헤더 보임/숨김
      final shouldShow = _scroll.hasClients ? _scroll.offset < 24.0 : true;
      if (shouldShow != _showHeader && mounted) {
        setState(() => _showHeader = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchCtrl.dispose();
    _debouncer.dispose();
    _scroll.dispose();
    _hdrCtl.dispose();
    _listCtl.dispose();
    super.dispose();
  }

  Future<void> _load({required int page}) async {
    // 🛡️ 투자성향이 없으면 목록 API 호출 금지
    if (widget.investTypeName == null || widget.investTypeName!.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialized = true; // 화면은 표시하되, 데이터 없음 상태
          _items = [];
          _page = null;
        });
      }
      return;
    }

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
      if (_selType != '전체') {
        list = list.where((e) => e.type == _selType).toList();
      }

      if (page == 0) {
        _items = list;
        _firstPageCount = _items.length;
        _animateFirstPage = true;
        _listCtl.reset();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _listCtl.forward();
        });
      } else {
        _items.addAll(list);
        _animateFirstPage = false;
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
    decoration: BoxDecoration(
      color: _chipBg(text),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
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
                            '펀드 가입',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 2) 검색바
                        __SlideFade(
                          t: _tSearch,
                          child: Align(
                            alignment: Alignment.center,
                            child: FractionallySizedBox(
                              widthFactor: 0.86,
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                onChanged: (_) =>
                                    _debouncer.run(() => _load(page: 0)),
                                onSubmitted: (_) => _load(page: 0),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: '펀드를 검색해보세요',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: tossBlue,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: tossBlue,
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: tossBlue,
                                      width: 1.6,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // 3) 유형 칩
                        __SlideFade(
                          t: _tChips,
                          child: SizedBox(
                            height: 44,
                            child: _ChipsRow(
                              items: _typeChips,
                              selected: _selType,
                              onSelected: (v) {
                                FocusScope.of(context).unfocus();
                                setState(() => _selType = v);
                                _load(page: 0);
                              },
                              leadingBuilder: (t, sel) {
                                final path = chipIconPaths[t];
                                if (path == null) {
                                  return Icon(
                                    Icons.category,
                                    size: 16,
                                    color: sel ? tossBlue : Colors.black87,
                                  );
                                }
                                return Image.asset(
                                  path,
                                  width: 16,
                                  height: 16,
                                  filterQuality: FilterQuality.medium,
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
    final screenH = MediaQuery.of(context).size.height;
    final headerH = (screenH * 0.33).clamp(220.0, 380.0);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _picked.isEmpty
          ? null
          : _CompareFab(
              open: _fabOpen,
              canOpen: _picked.length >= 2,
              selectedCount: _picked.length,
              onCompare: () {
                final selected = _items
                    .where((f) => _picked.contains(f.fundId))
                    .toList();
                final views = selected.map((f) {
                  final risk = f.badges.firstWhere(
                    (x) => x.startsWith('위험'),
                    orElse: () => '위험(-)',
                  );
                  return CompareFundView(
                    fundId: f.fundId,
                    name: f.name,
                    type: f.type,
                    managementCompany: f.subName.isEmpty ? null : f.subName,
                    riskText: risk,
                    return1m: f.return1m,
                    return3m: f.return3m,
                    return12m: f.return12m,
                  );
                }).toList();
                showCompareModal(context, views);
              },
              onAiCompare: () async {
                if (_picked.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('최소 2개 이상 담아야 AI 비교가 가능해요.')),
                  );
                  return;
                }
                final pickedOrder = _picked.toList();
                final selected =
                    _items.where((f) => _picked.contains(f.fundId)).toList()
                      ..sort(
                        (x, y) => pickedOrder
                            .indexOf(x.fundId)
                            .compareTo(pickedOrder.indexOf(y.fundId)),
                      );
                final top2 = selected.take(2).toList();
                final views = top2
                    .map(
                      (f) => CompareFundView(
                        fundId: f.fundId,
                        name: f.name,
                        type: f.type,
                        managementCompany: f.subName.isEmpty ? null : f.subName,
                        riskText: f.badges.firstWhere(
                          (x) => x.startsWith('위험'),
                          orElse: () => '위험(-)',
                        ),
                        return1m: f.return1m,
                        return3m: f.return3m,
                        return12m: f.return12m,
                      ),
                    )
                    .toList();

                try {
                  await showAiCompareSheetFromViews(
                    context,
                    views: views,
                    accessToken: widget.accessToken!,
                    baseUrl: ApiConfig.baseUrl,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('AI 비교 호출 실패: $e')));
                }
              },
              onBlocked: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('최소 2개 이상 담아야 비교할 수 있어요.')),
                );
              },
              onMenuOpenChanged: (open) {
                if (mounted) setState(() => _fabOpen = open);
              },
            ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, _) {
                return (!_initialized && _loading)
                    ? const Center(
                        child: CircularProgressIndicator(color: tossBlue),
                      )
                    : RefreshIndicator(
                        key: _refreshKey,
                        onRefresh: () async {
                          try {
                            await _load(page: 0);
                          } finally {
                            _autoRefreshing = false; // ✅ 끝나면 해제
                          }
                        },
                        // 스피너를 더 아래에서 보이게 → 체감상 덜 민감
                        edgeOffset: headerH + 8,
                        displacement: headerH + 36,
                        color: tossBlue,
                        backgroundColor: Colors.white,
                        strokeWidth: 2.6,
                        notificationPredicate: (n) => n.depth == 0,
                        child: Container(
                          color: pastel(tossBlue),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              final atTop = n.metrics.extentBefore == 0;

                              if (atTop) {
                                if (n is OverscrollNotification &&
                                    n.overscroll < 0) {
                                  _pullAccum += -n.overscroll;
                                } else if (n is ScrollUpdateNotification) {
                                  final d = n.scrollDelta ?? 0;
                                  if (d < 0) _pullAccum += -d;
                                }

                                // 임계 넘으면 플래그만 세팅 (즉시 새로고침 금지)
                                if (_pullAccum >= kPullToRefreshThreshold) {
                                  _pulledEnough = true;
                                }

                                // 손을 뗐을 때만 실제 트리거
                                if (n is ScrollEndNotification) {
                                  final now = DateTime.now();
                                  final cooledDown =
                                      _lastRefreshAt == null ||
                                      now.difference(_lastRefreshAt!) >=
                                          kRefreshCooldown;

                                  if (!_loading &&
                                      !_autoRefreshing &&
                                      _pulledEnough &&
                                      cooledDown) {
                                    _autoRefreshing = true;
                                    _lastRefreshAt = now;
                                    _refreshKey.currentState?.show();
                                  }

                                  // 초기화
                                  _pullAccum = 0.0;
                                  _pulledEnough = false;
                                }
                              } else {
                                // 맨 위가 아니면 누적/플래그 초기화
                                if (n is ScrollUpdateNotification) {
                                  _pullAccum = 0.0;
                                  _pulledEnough = false;
                                }
                              }
                              return false;
                            },
                            child: CustomScrollView(
                              controller: _scroll,
                              physics: const AlwaysScrollableScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              slivers: [
                                // ① 헤더
                                SliverToBoxAdapter(
                                  child: Container(
                                    color: Colors.white,
                                    child: _buildHeader(headerH),
                                  ),
                                ),
                                // ② 목록
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    16,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      ctx,
                                      i,
                                    ) {
                                      if (i == _items.length) {
                                        if (_loading) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: tossBlue,
                                              ),
                                            ),
                                          );
                                        }
                                        if (!(_page?.hasNext ?? false)) {
                                          return const SizedBox(height: 24);
                                        }
                                        return const SizedBox.shrink();
                                      }

                                      final f = _items[i];

                                      Animation<double> it;
                                      if (_animateFirstPage &&
                                          i < _firstPageCount) {
                                        final start = (i * 0.06).clamp(
                                          0.0,
                                          0.9,
                                        );
                                        final end = (start + 0.4).clamp(
                                          0.0,
                                          1.0,
                                        );
                                        it = CurvedAnimation(
                                          parent: _listCtl,
                                          curve: Interval(
                                            start,
                                            end,
                                            curve: Curves.easeOut,
                                          ),
                                        );
                                      } else {
                                        it = const AlwaysStoppedAnimation(1.0);
                                      }

                                      final selected = _isPicked(f.fundId);

                                      final card = _Pressable(
                                        child: Material(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            side: selected
                                                ? const BorderSide(
                                                    color: tossBlue,
                                                    width: 1.6,
                                                  )
                                                : BorderSide.none,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      FundDetailScreen(
                                                        fundId: f.fundId,
                                                        title: f.name,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // 위 라벨/설정일 행
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: tossBlue
                                                              .withOpacity(
                                                                0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          _divisionOf(f),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color: tossBlue,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      if (f.launchedAt != null)
                                                        Text(
                                                          '설정일 ${_fmtDate(f.launchedAt!)}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),

                                                  // 제목/서브
                                                  Text(
                                                    f.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    f.subName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize: 12,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 10),

                                                  // 위험/유형 칩
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Flexible(
                                                        child: Wrap(
                                                          spacing: 6,
                                                          runSpacing: 6,
                                                          alignment:
                                                              WrapAlignment
                                                                  .start,
                                                          crossAxisAlignment:
                                                              WrapCrossAlignment
                                                                  .center,
                                                          children: [
                                                            if (f.badges.any(
                                                              (b) =>
                                                                  b.startsWith(
                                                                    '위험',
                                                                  ),
                                                            ))
                                                              _badgeChip(
                                                                f.badges.firstWhere(
                                                                  (b) => b
                                                                      .startsWith(
                                                                        '위험',
                                                                      ),
                                                                ),
                                                              ),
                                                            _badgeChip(f.type),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 15),

                                                  // 수익률 + 담기 버튼
                                                  Row(
                                                    children: [
                                                      _PickChipButton(
                                                        selected: selected,
                                                        enabled:
                                                            selected ||
                                                            _picked.length < 2,
                                                        onTap: () {
                                                          HapticFeedback.selectionClick();
                                                          _togglePick(f.fundId);
                                                        },
                                                      ),
                                                      const Spacer(),
                                                      const Text(
                                                        '1개월 수익률',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '${f.return1m.toStringAsFixed(2)}%',
                                                        style: _ret(f.return1m),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );

                                      return __SlideFade(
                                        t: it,
                                        dy: .06,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: card,
                                        ),
                                      );
                                    }, childCount: _items.length + 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
              },
            ),

            // FAB 열렸을 때 터치 배리어
            if (_fabOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _fabOpen = false),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
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
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
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

  final Widget Function(String item, bool selected)? leadingBuilder;
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
            : Icon(
                icon ?? Icons.category,
                size: 16,
                color: sel ? tossBlue : Colors.black87,
              );

        return ChipTheme(
          data: ChipTheme.of(context).copyWith(showCheckmark: false),
          // ✅ 체크마크 비활성화
          child: ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [leading, const SizedBox(width: 6), Text(t)],
            ),
            selected: sel,
            onSelected: (_) => onSelected(t),
            selectedColor: tossBlue.withOpacity(.1),
            backgroundColor: Colors.white,
            side: BorderSide(color: sel ? tossBlue : Colors.black26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: items.length,
    );
  }
}

class _CompareFab extends StatefulWidget {
  final bool open;
  final bool canOpen; // 2개 이상 담겼는지
  final int selectedCount; // 담긴 개수 배지 표시용
  final VoidCallback onCompare; // 펀드 비교
  final VoidCallback onAiCompare; // AI 비교
  final VoidCallback onBlocked; // 2개 미만일 때 안내
  final void Function(bool open)? onMenuOpenChanged;

  const _CompareFab({
    required this.open,
    required this.canOpen,
    required this.selectedCount,
    required this.onCompare,
    required this.onAiCompare,
    required this.onBlocked,
    this.onMenuOpenChanged,
  });

  @override
  State<_CompareFab> createState() => _CompareFabState();
}

class _CompareFabState extends State<_CompareFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _t = CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);
    if (widget.open) _ctl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _CompareFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) {
      if (widget.open) {
        _ctl.forward();
      } else {
        _ctl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _requestToggle() {
    FocusScope.of(context).unfocus();
    if (!widget.canOpen) {
      widget.onBlocked();
      return;
    }
    widget.onMenuOpenChanged?.call(!widget.open);
  }

  Widget _miniPill(
    String label,
    IconData icon,
    VoidCallback onTap, {
    double width = 132,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          widget.onMenuOpenChanged?.call(false);
          onTap();
        },
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tossBlue.withOpacity(0.7), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0F172A)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool open = widget.open;

    return SizedBox(
      width: 88,
      height: open ? 220 : 88,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // 펼쳐지는 메뉴
          Positioned(
            right: 0,
            bottom: 72,
            child: IgnorePointer(
              ignoring: !open,
              child: FadeTransition(
                opacity: _t,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .1),
                    end: Offset.zero,
                  ).animate(_t),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _miniPill(
                        'AI 비교',
                        Icons.auto_awesome,
                        widget.onAiCompare,
                      ),
                      const SizedBox(height: 8),
                      _miniPill(
                        '비교 보기',
                        Icons.inventory_2_rounded,
                        widget.onCompare,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // FAB 본체
          FloatingActionButton(
            onPressed: _requestToggle,
            backgroundColor: tossBlue,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 0,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 180),
              turns: open ? 0.25 : 0,
              child: const Icon(Icons.compare_arrows_rounded, size: 35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickChipButton extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PickChipButton({
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const double kChipH = 30.0;
    const double kChipW = 72.0;

    final Color border = enabled || selected
        ? tossBlue
        : tossBlue.withOpacity(.35);
    final Color bg = selected ? tossBlue : Colors.white;
    final Color fg = selected
        ? Colors.white
        : (enabled ? tossBlue : tossBlue.withOpacity(.45));

    return SizedBox(
      height: kChipH,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled || selected ? onTap : null,
          child: SizedBox(
            width: kChipW,
            height: kChipH,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                transitionBuilder: (c, a) =>
                    FadeTransition(opacity: a, child: c),
                layoutBuilder: (current, prev) => Stack(
                  alignment: Alignment.center,
                  children: [...prev, if (current != null) current],
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        key: const ValueKey('picked'),
                        size: 18,
                        color: fg,
                      )
                    : Text(
                        '비교 담기 +',
                        key: const ValueKey('add'),
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
