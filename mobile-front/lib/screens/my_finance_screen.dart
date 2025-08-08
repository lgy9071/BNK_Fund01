import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fund.dart'; // Fund(id, name, rate, balance, featured) 모델

/* 공통 색 */
const tossBlue = Color(0xFF0064FF);
const tossGray = Color(0xFF202632);
Color pastel(Color c) => c.withOpacity(.12);

/* 데이터 모델 (위치에 따라 중복 정의하지 않으셨다면 생략해도 됩니다) */
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

/* 내 금융 화면 */
class MyFinanceScreen extends StatefulWidget {
  const MyFinanceScreen({super.key});
  @override
  State<MyFinanceScreen> createState() => _MyFinanceScreenState();
}

class _MyFinanceScreenState extends State<MyFinanceScreen> {
  final _accounts = <BankAccount>[
    BankAccount(bank: '국민 은행', maskedNumber: '123-4567-****', balance: 50_000),
    BankAccount(bank: '부산 은행', maskedNumber: '234-5678-****', balance: 70_000),
    BankAccount(bank: '우리 은행', maskedNumber: '345-6789-****', balance: 30_000),
  ];

  final _funds = <Fund>[
    Fund(id: 1, name: '글로벌채권펀드', rate:  3.2, balance: 4_000_000, featured: true),
    Fund(id: 2, name: '테크성장펀드',   rate: -1.1, balance: 3_000_000),
    Fund(id: 3, name: '헬스케어펀드',   rate:  2.5, balance: 2_500_000, featured: true),
    Fund(id: 4, name: '친환경펀드',     rate:  1.8, balance: 1_800_000),
  ];

  String _won(int v) =>
      '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';

  int get _totalAssets =>
      _accounts.fold<int>(0, (s, e) => s + e.balance) +
          _funds.fold<int>(0, (s, e) => s + e.balance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 금융'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) 총 자산 제목
            const Text('총 자산',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // 총 자산 금액 박스 (파스텔 회색)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: pastel(tossGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _won(_totalAssets),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black),
              ),
            ),
            const SizedBox(height: 24),

            // 2) 입출금 계좌
            const Text('입출금 계좌',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _SlidingCardSection<BankAccount>(
              items: _accounts,
              pageSize: 2,
              indicatorActive: Colors.black,
              itemBuilder: (ctx, a) => _accountCard(a),
            ),
            const SizedBox(height: 24),

            // 3) 가입 펀드
            const Text('가입 펀드',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _SlidingCardSection<Fund>(
              items: _funds,
              pageSize: 2,
              indicatorActive: Colors.black,
              itemBuilder: (ctx, f) => _fundCard(f),
            ),
          ],
        ),
      ),
    );
  }

  // 계좌 카드
  Widget _accountCard(BankAccount a) {
    return Card(
      color: pastel(tossBlue),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(children: [
          Expanded(
            child: Text('${a.bank}  ${a.maskedNumber}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
          ),
          Text(_won(a.balance),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
        ]),
      ),
    );
  }

  // 펀드 카드
  Widget _fundCard(Fund f) {
    final up    = f.rate >= 0;
    final icon  = up ? '▲' : '▼';
    final color = up ? Colors.red : Colors.blue;

    return Card(
      color: pastel(tossBlue),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(children: [
          // 왼쪽: 펀드명
          Expanded(
            child: Text(f.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black)),
          ),

          // 오른쪽: 잔액 위 수익률 아래
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_won(f.balance),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 4),
              Text('$icon ${f.rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),

          const SizedBox(width: 8),

          // 별 아이콘
          IconButton(
            icon: Icon(
              f.featured ? Icons.star : Icons.star_border,
              color: f.featured ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                f.featured = !f.featured;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(f.featured
                      ? '즐겨찾기에 등록되었습니다!'
                      : '즐겨찾기에서 해제되었습니다.'),
                ),
              );
            },
            tooltip: '즐겨찾기',
          ),
        ]),
      ),
    );
  }
}

/* 세로 슬라이드 카드 섹션 (2개씩) */
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
  static const double _itemH = 95.0; // 카드 높이 ↑
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
    final cnt   = widget.items.length;
    final pages = (cnt + widget.pageSize - 1) ~/ widget.pageSize;
    final totalH = widget.pageSize * _itemH + (widget.pageSize - 1) * _gap;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: totalH,
        child: PageView.builder(
          controller: _controller,
          itemCount: pages,
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
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < pages; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _current ? 10 : 8,
            height: i == _current ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.indicatorActive.withOpacity(i == _current ? 1 : .25),
            ),
          ),
      ]),
    ]);
  }
}