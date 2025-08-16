import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_front/core/routes/routes.dart';

class InvestResultScreen extends StatelessWidget {
  final Map<String, dynamic> result; // 서버에서 받은 RiskResultView JSON
  const InvestResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // 필드명이 확정 안 됐어도 안전하게 뽑기
    final grade = result['grade'] ?? result['riskGrade'] ?? '-';
    final score = result['score'] ?? result['totalScore'] ?? '-';
    final type  = result['type']  ?? result['profileType'] ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('투자성향 결과')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('등급: $grade', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('점수: $score', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('유형: $type', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('디버그 상세(JSON)'),
              children: [
                SelectableText(const JsonEncoder.withIndent('  ').convert(result)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
              },
              child: const Text('홈으로'),
            ),
          ),
        ),
      ),
    );
  }
}
