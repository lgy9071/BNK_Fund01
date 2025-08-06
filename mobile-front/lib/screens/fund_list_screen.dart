import 'package:flutter/material.dart';
import '../models/fund.dart';
import '../core/services/fund_service.dart';
import '../widgets/fund_card.dart';

class FundListScreen extends StatefulWidget {
  const FundListScreen({super.key});
  @override
  State<FundListScreen> createState() => _FundListScreenState();
}

class _FundListScreenState extends State<FundListScreen> {
  late Future<List<Fund>> _futureFunds;
  final _service = FundService();

  @override
  void initState() {
    super.initState();
    _futureFunds = _service.fetchFunds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('펀드 가입 가능 목록')),
      body: FutureBuilder<List<Fund>>(
        future: _futureFunds,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('오류: ${snap.error}'));
          }
          final funds = snap.data!;
          return ListView.builder(
            itemCount: funds.length,
            itemBuilder: (ctx, i) => FundCard(fund: funds[i]),
          );
        },
      ),
    );
  }
}
