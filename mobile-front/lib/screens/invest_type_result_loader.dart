import 'package:flutter/material.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/services/invest_result_service.dart';
import 'invest_type_result_screen.dart';
import 'package:mobile_front/core/constants/colors.dart';

class InvestTypeResultLoader extends StatelessWidget {
  /// 🔙 Backward-compatible (route에서 전달하던 값과의 호환 목적)
  /// 서버는 토큰에서 UID를 주입(@CurrentUid)하므로 실제로 사용되진 않습니다.
  @Deprecated('서버에서 토큰으로 UID 주입. 라우트 호환만을 위해 남겨둠.')
  final int? userId;

  @Deprecated('하루 1회 제한은 서버 eligibility로 판단. 라우트 호환 전용.')
  final DateTime? lastRetestAt;

  final InvestResultService service;

  const InvestTypeResultLoader({
    super.key,
    this.userId,                 // ← 라우트에서 넘어와도 무시됨
    required this.service,
    this.lastRetestAt,           // ← 라우트에서 넘어와도 무시됨
  });

  Future<_IntroBundle> _load() async {
    // 두 API 병렬 호출
    final latestF = service.fetchLatest();
    final eligF = service.fetchEligibility();
    final results = await Future.wait([latestF, eligF]);
    return _IntroBundle(
      latest: results[0] as InvestResultModel?,
      eligibility: results[1] as InvestEligibilityResponse,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_IntroBundle>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('투자성향분석'), centerTitle: true,),
            body: Center(child: Text('오류: ${snap.error}')),
          );
        }

        final data = snap.data!;
        return InvestTypeResultScreen(
          result: data.latest,            // null이면 “분석 시작” UI
          eligibility: data.eligibility,  // 오늘 재분석 가능 여부
          onStartAssessment: () async {
            // ⛳️ 핵심 수정: 결과가 null일 수 있으므로 bool? 제네릭 사용
            final bool? res = await Navigator.pushNamed<bool?>(
              context,
              AppRoutes.investTest,
            );
            // 새로고침 신호(pop(true)) 유지
            return res == true;
          },
        );
      },
    );
  }
}

class _IntroBundle {
  final InvestResultModel? latest;
  final InvestEligibilityResponse eligibility;
  _IntroBundle({required this.latest, required this.eligibility});
}