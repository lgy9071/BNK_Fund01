import 'package:flutter/material.dart';
import 'package:mobile_front/core/services/invest_result_service.dart';
import 'package:mobile_front/screens/invest_type_result_screen.dart';

class InvestTypeResultLoader extends StatelessWidget {
  final int userId;                     // 로그인 유저 USER_ID
  final DateTime? lastRetestAt;
  final InvestResultService service;

  const InvestTypeResultLoader({
    super.key,
    required this.userId,
    required this.service,
    this.lastRetestAt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InvestResultModel?>(
      future: service.fetchLatest(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('투자성향 결과')),
            body: Center(child: Text('오류: ${snap.error}')),
          );
        }
        return InvestTypeResultScreen(
          result: snap.data,                 // null이면 “분석 시작” UI
          lastRetestAt: lastRetestAt,
          onStartAssessment: () {
            Navigator.pushNamed(context, '/invest-test');
          },
        );
      },
    );
  }
}