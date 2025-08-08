import 'package:flutter/material.dart';
import '../screens/fund_join_screen.dart' show JoinFund; // JoinFund 재사용

class FundDetailScreen extends StatelessWidget {
  final JoinFund fund;
  const FundDetailScreen({super.key, required this.fund});

  @override
  Widget build(BuildContext context) {
    TextStyle ret(double v) => TextStyle(
      color: v >= 0 ? Colors.red : Colors.blue,
      fontWeight: FontWeight.bold,
    );
    String fmt(double v) => '${v.toStringAsFixed(2)}%';

    return Scaffold(
      appBar: AppBar(title: Text(fund.name)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fund.subName,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: fund.badges
                  .map((b) => Chip(label: Text(b)))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('설정일 : ${fund.launchedAt.toLocal().toString().split(' ')[0]}'),
            const SizedBox(height: 20),
            Text('수익률', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  const Text('1M'),
                  Text(fmt(fund.return1m), style: ret(fund.return1m))
                ]),
                Column(children: [
                  const Text('3M'),
                  Text(fmt(fund.return3m), style: ret(fund.return3m))
                ]),
                Column(children: [
                  const Text('12M'),
                  Text(fmt(fund.return12m), style: ret(fund.return12m))
                ]),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                // TODO : 가입 로직
              },
              child: const Text('이 펀드 가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}