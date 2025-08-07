import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fund.dart'; // ───────────────────────── 모델: featured 포함

/* ───── 공통 색상 ─────────────────────────────────────────────── */
const tossBlue = Color(0xFF0064FF);
const tossGray = Color(0xFF202632);

/* ───── 데모용 모델 ───────────────────────────────────────────── */
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

/* ───── 세로 슬라이드 카드 섹션 (2개씩) ───────────────────────── */
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
  State<_SlidingCardSection<T>> createState() => _SlidingCardSectionState<T>();
}

class _SlidingCardSectionState<T> extends State<_SlidingCardSection<T>> {
  late final PageController _controller;
  int _current = 0;

  static const double _itemH = 80.0;
  static const double _gap   = 8.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController()
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
    final cnt = widget.items.length;
    final pageCnt = (cnt + widget.pageSize - 1) ~/ widget.pageSize;
    final totalH  = widget.pageSize * _itemH + (widget.pageSize - 1) * _gap;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: totalH,
          child: PageView.builder(
            controller: _controller,
            itemCount: pageCnt,
            itemBuilder: (ctx, page) {
              final start = page * widget.pageSize;
              final end   = math.min(start + widget.pageSize, cnt);
              final slice = widget.items.sublist(start, end);
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var item in slice)
                    SizedBox(
                      height: _itemH,
                      child: widget.itemBuilder(ctx, item),
                    ),
                  if (slice.length < widget.pageSize)
                    for (int i = slice.length; i < widget.pageSize; i++)
                      const SizedBox(height: _itemH),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCnt, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width:  active ? 10 : 8,
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

/* ───── 배경 카드 ─────────────────────────────────────────────── */
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/* ───── 내 금융 화면 ──────────────────────────────────────────── */
class MyFinanceScreen extends StatefulWidget {
  const MyFinanceScreen({super.key});

  @override
  State<MyFinanceScreen> createState() => _MyFinanceScreenState();
}

class _MyFinanceScreenState extends State<MyFinanceScreen> {
  /* 데모 데이터 --------------------------------------------------- */
  final _accounts = <BankAccount>[
    BankAccount(bank: '국민 은행', maskedNumber: '123-4567-****', balance: 50_000),
    BankAccount(bank: '부산 은행', maskedNumber: '234-5678-****', balance: 70_000),
    BankAccount(bank: '우리 은행', maskedNumber: '345-6789-****', balance: 30_000),
  ];

  final _funds = <Fund>[
    Fund(id: 1, name: '글로벌채권펀드',    rate:  3.2, balance: 4_000_000, featured: true),
    Fund(id: 2, name: '테크성장펀드',      rate: -1.1, balance: 3_000_000, featured: false),
    Fund(id: 3, name: '헬스케어펀드',      rate:  2.5, balance: 2_500_000, featured: true),
    Fund(id: 4, name: '친환경펀드',        rate:  1.8, balance: 1_800_000, featured: false),
  ];

  /* 유틸 ----------------------------------------------------------- */
  String _won(int v) =>
      v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') + '원';

  int get _totalAssets =>
      _accounts.fold<int>(0, (s, e) => s + e.balance) +
          _funds.fold<int>(0, (s, e) => s + e.balance);

  /* build ---------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 금융'), backgroundColor: tossBlue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* 총 자산 ------------------------------------------------ */
            SectionCard(
              title: '총 자산',
              background: tossGray,
              child: Text(
                _won(_totalAssets),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700),
              ),
            ),

            /* 입출금 계좌 ------------------------------------------ */
            SectionCard(
              title: '입출금 계좌',
              background: tossBlue,
              child: _SlidingCardSection<BankAccount>(
                items: _accounts,
                pageSize: 2,
                indicatorActive: Colors.white,
                itemBuilder: (ctx, a) => _accountCard(ctx, a, _won(a.balance)),
              ),
            ),

            /* 가입 펀드 -------------------------------------------- */
            SectionCard(
              title: '가입 펀드',
              background: tossBlue,
              child: _SlidingCardSection<Fund>(
                items: _funds,
                pageSize: 2,
                indicatorActive: Colors.white,
                itemBuilder: (ctx, f) => _fundCard(
                    ctx, f, _won(f.balance), () => _toggleFeatured(f)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* 카드 ------------------------------------------------------------------ */
  Widget _accountCard(BuildContext context, BankAccount a, String right) => Card(
    color: Colors.white,
    elevation: .5,
    shape:
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text('${a.bank}  ${a.maskedNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(right,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _fundCard(BuildContext context, Fund f, String right,
      VoidCallback toggleFeatured) {
    final color = f.rate >= 0 ? Colors.red : Colors.blue;
    return Card(
      color: Colors.white,
      elevation: .5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            /* 좌측: 펀드명 + 수익률 ------------------------------ */
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${f.rate >= 0 ? '+' : ''}${f.rate.toStringAsFixed(2)}%',
                    style:
                    TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            /* 우측: 금액 ---------------------------------------- */
            Text(right,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            /* 대표 펀드 지정 ⭐ ---------------------------------- */
            IconButton(
              icon: Icon(
                f.featured ? Icons.star : Icons.star_border,
                color: f.featured ? Colors.amber : Colors.grey,
              ),
              tooltip: '홈 화면에 표시',
              onPressed: toggleFeatured,
            ),
          ],
        ),
      ),
    );
  }

  /* 대표 펀드 토글 --------------------------------------------------------- */
  void _toggleFeatured(Fund f) => setState(() => f.featured = !f.featured);
}