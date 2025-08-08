import 'package:flutter/material.dart';
import '../models/fund.dart';

class FundCard extends StatelessWidget {
  final Fund fund;
  const FundCard({super.key, required this.fund});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(fund.name),
        subtitle: Text('수익률: ${fund.rate.toStringAsFixed(2)}%'),
        trailing: Text('${fund.balance}원'),
        onTap: () {
          // TODO: 펀드 상세 페이지로 이동
        },
      ),
    );
  }
}