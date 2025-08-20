import 'package:flutter/material.dart';
import 'package:mobile_front/core/services/invest_result_service.dart';
import 'package:mobile_front/screens/invest_type_result_screen.dart';
import 'package:mobile_front/core/routes/routes.dart'; // AppRoutes 사용
import 'package:mobile_front/core/constants/colors.dart';

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
            body: Center(child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
            )),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('투자성향분석')),
            body: Center(child: Text('오류: ${snap.error}')),
          );
        }

        return InvestTypeResultScreen(
          result: snap.data,           // null이면 “분석 시작” UI
          lastRetestAt: lastRetestAt,
          // ✅ 도입부에서 "재(분)석 시작" 시 설문 라우트로 진입
          // 결과 플로우 끝에서 Navigator.pop(true) 되면 여기서 true를 받음
          onStartAssessment: () async {
            final bool? res = await Navigator.pushNamed<bool>(
              context,
              AppRoutes.investTest,    // <-- '/invest-test' 대신 상수 사용
            );
            return res == true;        // true면 상위에서 pop(true) 전파
          },
        );
      },
    );
  }
}
