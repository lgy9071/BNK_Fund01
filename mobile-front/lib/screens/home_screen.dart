import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fund.dart';                     // Fund 모델: featured 필드 포함

/* 공통 색 */
const tossBlue = Color(0xFF0064FF);
const tossGray = Color(0xFF202632);
Color pastel(Color c) => c.withOpacity(.12);

/* ─── 홈 화면 ───────────────────────────────────────────── */
class HomeScreen extends StatefulWidget {
  final List<Fund> myFunds;
  final String investType;
  final String userName;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.myFunds,
    required this.investType,
    required this.userName,
    required this.onToggleTheme,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _obscure = false;                         // 잔액 가리기 토글

  String _won(int v) =>
      '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';

  @override
  Widget build(BuildContext context) {
    final showFunds = widget.myFunds.where((f) => f.featured).toList();
    final totalBal  = showFunds.fold<int>(0, (s, f) => s + f.balance);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /* ── 헤더 ── */
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet, color: Colors.black),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('BNK 펀드',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.black54),
                    onPressed: () {}),
                IconButton(
                    icon: const Icon(Icons.dark_mode, color: Colors.black54),
                    onPressed: widget.onToggleTheme,),
              ]),
            ),

            /* ── 본문 ── */
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  /* 투자성향 카드 */
                  Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(
                      color: pastel(tossGray),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${widget.userName} 님의 투자성향',
                                style: const TextStyle(fontSize: 14, color: Colors.black)),
                            const SizedBox(height: 6),
                            Text(widget.investType,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: TextButton(
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero, foregroundColor: tossGray),
                          onPressed: () {/* TODO: 상세 이동 */},
                          child: const Text('자세히 보기'),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  /* 총 평가금액 카드 */
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      color: pastel(tossBlue),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        const Text('총 평가금액',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_horiz, color: Colors.black54),
                          onSelected: (_) => setState(() => _obscure = !_obscure),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'toggle',
                                child: Text(_obscure ? '잔액보기' : '잔액 숨기기'))
                          ],
                        ),
                      ]),
                      const SizedBox(height: 8),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _obscure
                            ? Column(key: const ValueKey('hidden'), children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('잔액보기',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 14),
                          _FundsPager(myFunds: showFunds, obscure: true),
                        ])
                            : Column(key: const ValueKey('shown'), children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _won(totalBal),
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _FundsPager(myFunds: showFunds, obscure: false),
                        ]),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),
                  Text('추천/공지 섹션 자리',
                      style: TextStyle(color: Colors.grey[600])),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─── 펀드 슬라이드(2개씩) ─────────────────────────────── */
class _FundsPager extends StatefulWidget {
  final List<Fund> myFunds;
  final bool obscure;
  const _FundsPager({required this.myFunds, required this.obscure});
  @override
  State<_FundsPager> createState() => _FundsPagerState();
}

class _FundsPagerState extends State<_FundsPager> {
  late final PageController _c;
  int _cur = 0;
  static const double _h = 100, _gap = 10;

  @override
  void initState() {
    super.initState();
    _c = PageController()
      ..addListener(() {
        final p = _c.page?.round() ?? 0;
        if (p != _cur) setState(() => _cur = p);
      });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final f = widget.myFunds;
    if (f.isEmpty) {
      return const Text('대표 펀드 없음', style: TextStyle(color: Colors.black54));
    }
    final pages = (f.length + 1) ~/ 2;
    final pagerH = _h * 2 + _gap + 12;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: pagerH,
        child: PageView.builder(
          controller: _c,
          itemCount: pages,
          itemBuilder: (_, page) {
            final start = page * 2;
            final slice = f.sublist(start, math.min(start + 2, f.length));
            return Column(children: [
              for (int i = 0; i < slice.length; i++) ...[
                _FundMiniCard(fund: slice[i], obscure: widget.obscure),
                if (i != slice.length - 1) const SizedBox(height: _gap),
              ]
            ]);
          },
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < pages; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _cur ? 10 : 8,
            height: i == _cur ? 10 : 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(i == _cur ? 1 : .25)),
          ),
      ]),
    ]);
  }
}

/* ─── 펀드 카드 ────────────────────────────────────────── */
class _FundMiniCard extends StatelessWidget {
  final Fund fund;
  final bool obscure;
  const _FundMiniCard({required this.fund, required this.obscure});

  @override
  Widget build(BuildContext context) {
    final up    = fund.rate >= 0;
    final icon  = up ? '▲' : '▼';
    final color = up ? Colors.red : Colors.blue;

    return SizedBox(
      height: _FundsPagerState._h,
      child: Card(
        color: Colors.white,                                  // ← 흰 배경으로 고정
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: .8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(fund.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!obscure)
                  Text(
                    '${fund.balance.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                const SizedBox(height: 2),
                Text('$icon ${fund.rate.toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: obscure ? 22 : 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}