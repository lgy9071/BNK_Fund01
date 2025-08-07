import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fund.dart';
import 'dart:ui';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  final List<Fund> myFunds;
  final String investType;
  final String userName;

  const HomeScreen({
    super.key,
    required this.myFunds,
    required this.investType,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _obscureBalance = false;

  String _formatWon(int v) =>
      v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') + '원';

  static const _investResultColor = Color(0xFF202632);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final _showFunds =
           widget.myFunds.where((f) => f.featured).toList(growable: false);
       final totalBalance =
           _showFunds.fold<int>(0, (s, f) => s + f.balance);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'BNK 펀드',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.dark_mode),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202632),  // Toss Gray
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E6F5)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${widget.userName} 님의 투자성향',
                            style: const TextStyle(
                              color: Color(0xFFF5F5F5), // 밝은 흰색
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.investType,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF5F5F5), // 밝은 흰색
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFF0064FF),
                      elevation: .6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '총 평가금액',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                                  onSelected: (value) {
                                    if (value == 'toggle') {
                                      setState(() => _obscureBalance = !_obscureBalance);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem<String>(
                                      value: 'toggle',
                                      child: Text(_obscureBalance ? '잔액 보이기' : '잔액 숨기기'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // 총 평가금액 + 펀드 목록 묶어서 블러 처리
                            _obscureBalance
                                ? ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 블러 강도
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatWon(totalBalance),
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _FundsPager(
                                    myFunds: _showFunds,
                                    indicatorActive: Colors.white,
                                  ),
                                ],
                              ),
                            )
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatWon(totalBalance),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _FundsPager(
                                  myFunds: widget.myFunds,
                                  indicatorActive: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '추천/공지 등 다른 섹션을 여기에 추가',
                      style: TextStyle(color: cs.onSurface.withOpacity(.7)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundsPager extends StatefulWidget {
  final List<Fund> myFunds;
  final Color indicatorActive;

  const _FundsPager({required this.myFunds, required this.indicatorActive});

  @override
  State<_FundsPager> createState() => _FundsPagerState();
}

class _FundsPagerState extends State<_FundsPager> {
  late final PageController _controller;
  int _current = 0;

  static const double _cardHeight = 92;
  static const double _gap = 10;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
    _controller.addListener(() {
      final p = _controller.page?.round() ?? 0;
      if (p != _current) setState(() => _current = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final funds = widget.myFunds;
    if (funds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('가입한 펀드가 없습니다.'),
      );
    }

    final pageCount = (funds.length + 2) ~/ 3;
    final double pagerHeight = _cardHeight * 3 + _gap * 2 + 12;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: pagerHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * 3;
              final end = math.min(start + 3, funds.length);
              final slice = funds.sublist(start, end);

              return Column(
                children: [
                  for (int i = 0; i < slice.length; i++) ...[
                    _FundMiniCard(fund: slice[i]),
                    if (i != slice.length - 1) const SizedBox(height: _gap),
                  ]
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (i) {
            final bool active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 10 : 8,
              height: active ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? widget.indicatorActive
                    : widget.indicatorActive.withOpacity(.25),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FundMiniCard extends StatelessWidget {
  final Fund fund;
  const _FundMiniCard({required this.fund});

  @override
  Widget build(BuildContext context) {
    // 수익률에 따라 빨강/파랑 색 지정
    final rateColor = fund.rate >= 0 ? Colors.red : Colors.blue;

    return SizedBox(
      height: _FundsPagerState._cardHeight,
      child: Card(
        color: Colors.white,
        elevation: .8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ── 좌측: 펀드명 + 수익률 ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 펀드명
                    Text(
                      fund.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 수익률 (컬러 적용)
                    Text(
                      '수익률: ${fund.rate.toStringAsFixed(2)}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        color: rateColor,
                      ),
                    ),
                  ],
                ),
              ),

              // ── 우측: 금액 (크고 굵게) ──
              Text(
                '${fund.balance.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') + '원'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}