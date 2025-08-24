// lib/screens/my_finance_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/services/user_service.dart';
import 'package:mobile_front/widgets/common_button.dart';
import '../models/fund.dart';

const tossBlue = Color(0xFF0064FF);
Color pastel(Color c) => c.withOpacity(.12);

class BankAccount {
  final String bank;
  final String maskedNumber;
  final int balance;
  BankAccount({required this.bank, required this.maskedNumber, required this.balance});
}

class MyFinanceScreen extends StatefulWidget {
  final String? accessToken;
  final UserService? userService;

  const MyFinanceScreen({
    super.key,
    this.accessToken,
    this.userService,
  });

  @override
  State<MyFinanceScreen> createState() => _MyFinanceScreenState();
}

class _MyFinanceScreenState extends State<MyFinanceScreen> {
  final _accounts = <BankAccount>[
    BankAccount(bank: '국민 은행', maskedNumber: '123-4567-****', balance: 500_000),
    BankAccount(bank: '부산 은행', maskedNumber: '234-5678-****', balance: 700_000),
    BankAccount(bank: '우리 은행', maskedNumber: '345-6789-****', balance: 300_000),
    BankAccount(bank: '하나 은행', maskedNumber: '456-7890-****', balance: 450_000),
  ];
  final _funds = <Fund>[
    Fund(id: 1, name: '글로벌채권펀드', rate: 3.2, balance: 4_000_000, featured: true),
    Fund(id: 2, name: '테크성장펀드',   rate: -1.1, balance: 3_000_000),
    Fund(id: 3, name: '헬스케어펀드',  rate: 2.5,  balance: 2_500_000, featured: true),
  ];
  final int _cash = 250_000;

  final int _inflow = 2_200_000;
  final int _outflow = 1_750_000;
  final int _prevInflow = 1_900_000;
  final int _prevOutflow = 1_900_000;

  String _won(int v) => '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';

  int get _sumAccounts => _accounts.fold(0, (s, a) => s + a.balance);
  int get _sumFunds => _funds.fold(0, (s, f) => s + f.balance);
  int get _totalAssets => _sumAccounts + _sumFunds + _cash;

  final Map<String, double> _target = const {'예·적금': .40, '펀드': .50, '현금': .10};
  final double _threshold = .05;

  @override
  Widget build(BuildContext context) {
    final actual = {
      '예·적금': _sumAccounts / _totalAssets,
      '펀드': _sumFunds / _totalAssets,
      '현금': _cash / _totalAssets,
    };
    final breaches = <String>[];
    _target.forEach((k, t) {
      final diff = (actual[k]! - t).abs();
      if (diff > _threshold) {
        final sign = actual[k]! > t ? '+' : '−';
        breaches.add('$k ${sign}${(diff * 100).toStringAsFixed(1)}%p');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('내 금융'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.fontColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 총 자산
            const Text('총 자산', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.fontColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: pastel(tossBlue)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(_won(_totalAssets),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.fontColor)),
              ),
            ),
            const SizedBox(height: 20),

            // 자산 분포 (도넛) + 설명
            const _SectionHeader(
              title: '자산 분포',
              subtitle: '예·적금/펀드/현금이 전체 자산에서 차지하는 비율을 한눈에 보여줍니다.',
            ),
            const SizedBox(height: 10),
            _DonutCard(sumAccounts: _sumAccounts, sumFunds: _sumFunds, cash: _cash, total: _totalAssets),
            const SizedBox(height: 20),

            // 이번 달 현금흐름 + 설명
            const _SectionHeader(
              title: '이번 달 현금흐름',
              subtitle: '이번 달 유입/유출과 지난달 대비를 간단한 막대로 비교합니다.',
            ),
            const SizedBox(height: 10),
            _CashflowCard(
              inflow: _inflow, outflow: _outflow, prevInflow: _prevInflow, prevOutflow: _prevOutflow,
            ),
            const SizedBox(height: 20),

            // 리밸런싱 알림 + 설명
            const _SectionHeader(
              title: '리밸런싱',
              subtitle: '설정한 목표 비중(예·적금 40% / 펀드 50% / 현금 10%)에서 ±5%p 벗어나면 알려줍니다.',
            ),
            const SizedBox(height: 10),
            _RebalanceCard(breaches: breaches),
            const SizedBox(height: 24),

            // 입출금 계좌 — 2개씩 슬라이드
            const _SectionHeader(title: '입출금 계좌'),
            const SizedBox(height: 8),
            /*
            _SlidingCardSection<BankAccount>(
              items: _accounts,
              pageSize: 2,
              indicatorActive: AppColors.fontColor,
              itemBuilder: (ctx, a) => _AccountCard(a: a),
            ),
            */
            // 펀드 계좌 개설 버튼 추가
            CommonButton(
              text: '입출금 계좌 개설',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.otp,
                  arguments: {
                    'accessToken': widget.accessToken,
                    'userService': widget.userService,
                  },
                );
              },
            ),


            const SizedBox(height: 24),

            // 가입 펀드 — 2개씩 슬라이드
            const _SectionHeader(title: '가입 펀드'),
            const SizedBox(height: 8),
            _SlidingCardSection<Fund>(
              items: _funds,
              pageSize: 2,
              indicatorActive: AppColors.fontColor,
              itemBuilder: (ctx, f) => _FundRow(f: f),
            ),
          ],
        ),
      ),
    );
  }
}

/* 공통 섹션 헤더(설명 문구 포함 가능) */
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.fontColor)),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle!, style: TextStyle(fontSize: 12, color: AppColors.fontColor.withOpacity(.66))),
        ),
    ]);
  }
}

/* 도넛 카드 */
class _DonutCard extends StatelessWidget {
  final int sumAccounts, sumFunds, cash, total;
  const _DonutCard({required this.sumAccounts, required this.sumFunds, required this.cash, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: pastel(tossBlue)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _DonutPainter(values: [
                sumAccounts.toDouble(),
                sumFunds.toDouble(),
                cash.toDouble()
              ]),
              child: const Center(
                child: Text('비중', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.fontColor)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: const [
            _Legend(colorIndex: 0, label: '예·적금'),
            SizedBox(width: 12),
            _Legend(colorIndex: 1, label: '펀드'),
            SizedBox(width: 12),
            _Legend(colorIndex: 2, label: '현금'),
          ]),
        ],
      ),
    );
  }
}

/* 현금흐름 카드 */
class _CashflowCard extends StatelessWidget {
  final int inflow, outflow, prevInflow, prevOutflow;
  const _CashflowCard({
    required this.inflow, required this.outflow,
    required this.prevInflow, required this.prevOutflow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: pastel(tossBlue)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 120,
        child: CustomPaint(
          painter: _BarsPainter(
            inflow: inflow.toDouble(),
            outflow: outflow.toDouble(),
            prevInflow: prevInflow.toDouble(),
            prevOutflow: prevOutflow.toDouble(),
          ),
        ),
      ),
    );
  }
}

/* 리밸런싱 카드 */
class _RebalanceCard extends StatelessWidget {
  final List<String> breaches;
  const _RebalanceCard({required this.breaches});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: pastel(tossBlue)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: breaches.isEmpty
          ? const Text('목표 비중 내에서 잘 유지 중이에요.', style: TextStyle(color: AppColors.fontColor))
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text('목표 비중에서 벗어난 자산: ${breaches.join(', ')}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.fontColor)),
        ),
      ]),
    );
  }
}

/* 계좌 카드: 테두리만, 좌상=은행, 좌하=계좌번호 */
class _AccountCard extends StatelessWidget {
  final BankAccount a;
  const _AccountCard({required this.a});
  String _won(int v) => '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: pastel(tossBlue)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.bank, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.fontColor)),
              const SizedBox(height: 4),
              Text(a.maskedNumber, style: TextStyle(color: AppColors.fontColor.withOpacity(.7))),
            ],
          ),
        ),
        Text(_won(a.balance), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.fontColor)),
      ]),
    );
  }
}

/* 펀드 행 */
class _FundRow extends StatelessWidget {
  final Fund f;
  const _FundRow({required this.f});
  String _won(int v) => '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';
  @override
  Widget build(BuildContext context) {
    final up = f.rate >= 0;
    final c = up ? Colors.red : Colors.blue;
    final icon = up ? '▲' : '▼';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: pastel(tossBlue)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(
          child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.fontColor)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_won(f.balance), style: const TextStyle(color: AppColors.fontColor)),
          const SizedBox(height: 2),
          Text('$icon ${f.rate.toStringAsFixed(2)}%', style: TextStyle(color: c, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

/* 2개씩 묶어 수평 슬라이드 PageView */
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
  static const double _itemH = 88.0;
  static const double _gap = 8.0;

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
    final pages = (cnt + widget.pageSize - 1) ~/ widget.pageSize;
    final totalH = widget.pageSize * _itemH + (widget.pageSize - 1) * _gap;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: totalH,
          child: PageView.builder(
            controller: _controller,
            itemCount: pages,
            itemBuilder: (ctx, page) {
              final start = page * widget.pageSize;
              final end = math.min(start + widget.pageSize, cnt);
              final slice = widget.items.sublist(start, end);
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var item in slice)
                    SizedBox(height: _itemH, child: widget.itemBuilder(ctx, item)),
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
      ],
    );
  }
}

/* ====== 차트 Painters (Donut / Bars) ====== */
class _DonutPainter extends CustomPainter {
  final List<double> values;
  _DonutPainter({required this.values});

  static const _palette = [Color(0xFF6AA3FF), Color(0xFF3DDC97), Color(0xFFFFC85C)];

  @override
  void paint(Canvas canvas, Size size) {
    final sum = values.fold<double>(0, (s, v) => s + v);
    if (sum <= 0) return;

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = Colors.black12;
    canvas.drawCircle(center, radius, bg);

    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / sum) * 2 * math.pi;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 24
        ..color = _palette[i % _palette.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, p);
      start += sweep;
    }
    final hole = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - 16, hole);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values.join(',') != values.join(',');
}

class _Legend extends StatelessWidget {
  final int colorIndex;
  final String label;
  const _Legend({required this.colorIndex, required this.label});
  static const _palette = [Color(0xFF6AA3FF), Color(0xFF3DDC97), Color(0xFFFFC85C)];
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: _palette[colorIndex], shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppColors.fontColor)),
    ]);
  }
}

class _BarsPainter extends CustomPainter {
  final double inflow, outflow, prevInflow, prevOutflow;
  _BarsPainter({required this.inflow, required this.outflow, required this.prevInflow, required this.prevOutflow});

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = [inflow, outflow, prevInflow, prevOutflow].reduce(math.max);
    if (maxV <= 0) return;

    final barW = size.width / 6;
    final gap = barW;
    final baseY = size.height - 20;
    double h(double v) => (v / maxV) * (size.height - 30);

    final ghost = Paint()..color = Colors.black12;
    final inflowP = Paint()..color = const Color(0xFF3DDC97);
    final outflowP = Paint()..color = const Color(0xFFFF6B6B);

    // 지난달(희미)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gap, baseY - h(prevInflow), barW, h(prevInflow)), const Radius.circular(6)), ghost);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gap * 2 + barW, baseY - h(prevOutflow), barW, h(prevOutflow)), const Radius.circular(6)), ghost);

    // 이번달
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gap * 3 + barW * 2, baseY - h(inflow), barW, h(inflow)), const Radius.circular(6)), inflowP);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gap * 4 + barW * 3, baseY - h(outflow), barW, h(outflow)), const Radius.circular(6)), outflowP);
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      inflow != old.inflow || outflow != old.outflow || prevInflow != old.prevInflow || prevOutflow != old.prevOutflow;
}
