import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Toss 색상
const tossBlue = Color(0xFF0064FF);
const tossGray = Color(0xFF202632);

/// 데모용 모델
class BankAccount {
  final String bank;
  final String maskedNumber;
  final int balance;
  BankAccount({
    required this.bank,
    required this.maskedNumber,
    required this.balance,
  });
}

class FundHolding {
  final String name;
  final double rate; // 수익률 %
  final int amount;  // 평가금액(원)
  FundHolding({
    required this.name,
    required this.rate,
    required this.amount,
  });
}

/// 슬라이드 카드 섹션 (2개씩 페이징 + 점 인디케이터)
class _SlidingCardSection<T> extends StatefulWidget {
  final List<T> items;
  final int pageSize;
  final Color indicatorActive;
  final Widget Function(BuildContext context, T item) itemBuilder;

  const _SlidingCardSection({
    required this.items,
    required this.pageSize,
    required this.indicatorActive,
    required this.itemBuilder,
  });

  @override
  State<_SlidingCardSection<T>> createState() =>
      _SlidingCardSectionState<T>();
}

class _SlidingCardSectionState<T> extends State<_SlidingCardSection<T>> {
  late final PageController _controller;
  int _current = 0;

  static const double _itemHeight = 80.0;
  static const double _gap = 8.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0)
      ..addListener(() {
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
    final count = widget.items.length;
    final pageCount = (count + widget.pageSize - 1) ~/ widget.pageSize;
    final totalHeight =
        widget.pageSize * _itemHeight + (widget.pageSize - 1) * _gap;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: totalHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: pageCount,
            itemBuilder: (ctx, page) {
              final start = page * widget.pageSize;
              final end = math.min(start + widget.pageSize, count);
              final slice = widget.items.sublist(start, end);
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var item in slice)
                    SizedBox(
                      height: _itemHeight,
                      child: widget.itemBuilder(ctx, item),
                    ),
                  if (slice.length < widget.pageSize)
                    for (int i = slice.length; i < widget.pageSize; i++)
                      SizedBox(height: _itemHeight),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (i) {
            final active = i == _current;
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

/// 배경 카드 + 제목 + 자식 위젯 묶음
class SectionCard extends StatelessWidget {
  final String title;
  final Color background;
  final Widget child;
  const SectionCard({
    required this.title,
    required this.background,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// 내 금융 화면
class MyFinanceScreen extends StatelessWidget {
  MyFinanceScreen({super.key});

  // 데모 데이터
  final _accounts = <BankAccount>[
    BankAccount(bank: '국민 은행', maskedNumber: '123-4567-****', balance: 50_000),
    BankAccount(bank: '부산 은행', maskedNumber: '234-5678-****', balance: 70_000),
    BankAccount(bank: '우리 은행', maskedNumber: '345-6789-****', balance: 30_000),
  ];
  final _funds = <FundHolding>[
    FundHolding(name: '글로벌채권펀드', rate: 3.2, amount: 4_000_000),
    FundHolding(name: '테크성장펀드', rate: -1.1, amount: 3_000_000),
    FundHolding(name: '헬스케어펀드', rate: 2.5, amount: 2_500_000),
    FundHolding(name: '친환경펀드', rate: 1.8, amount: 1_800_000),
  ];

  String _won(int v) =>
      '₩' + v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');

  int get _totalAssets {
    final a = _accounts.fold<int>(0, (s, e) => s + e.balance);
    final f = _funds.fold<int>(0, (s, e) => s + e.amount);
    return a + f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 금융'),
        backgroundColor: tossBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 총 자산 카드 ──
            SectionCard(
              title: '총 자산',
              background: tossGray,
              child: Text(
                _won(_totalAssets),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // ── 입출금 계좌 카드 + 세로 2개 슬라이드 ──
            SectionCard(
              title: '입출금 계좌',
              background: tossBlue,
              child: _SlidingCardSection<BankAccount>(
                items: _accounts,
                pageSize: 2,
                indicatorActive: Colors.white,
                itemBuilder: (ctx, a) =>
                    _accountCard(ctx, a, _won(a.balance)),
              ),
            ),

            // ── 가입 펀드 카드 + 세로 2개 슬라이드 ──
            SectionCard(
              title: '가입 펀드',
              background: tossBlue,
              child: _SlidingCardSection<FundHolding>(
                items: _funds,
                pageSize: 2,
                indicatorActive: Colors.white,
                itemBuilder: (ctx, f) => _fundCard(ctx, f, _won(f.amount)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountCard(
      BuildContext context, BankAccount a, String right) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${a.bank}  ${a.maskedNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              right,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fundCard(
      BuildContext context, FundHolding f, String right) {
    final cs = Theme.of(context).colorScheme;
    final color = f.rate >= 0 ? Colors.red : Colors.blue;
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${f.rate >= 0 ? '+' : ''}${f.rate.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Text(
              right,
              style: TextStyle(
                  color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: tossBlue),
          ],
        ),
      ),
    );
  }
}