// lib/screens/invest_result_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/dev_jiyong/main_home.dart';
import 'package:mobile_front/widgets/step_header.dart';
import 'package:mobile_front/widgets/score_gauge.dart';

/// 제출 직후 결과 화면
/// Navigator.pushReplacementNamed(AppRoutes.investResult, arguments: Map<String, dynamic>) 로 진입
class InvestResultScreen extends StatefulWidget {
  final Map<String, dynamic>? result; // 선택: 직접 주입도 가능
  final int maxScore; // 만점(예: 65)

  const InvestResultScreen({
    super.key,
    this.result,
    this.maxScore = 65,
  });

  @override
  State<InvestResultScreen> createState() => _InvestResultScreenState();
}

class _InvestResultScreenState extends State<InvestResultScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic> _data = const {};

  // /api/me 결과
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // arguments 우선 적용
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (widget.result != null) {
        _data = widget.result!;
      } else if (arg is Map<String, dynamic>) {
        _data = arg;
      }
      setState(() {}); // 데이터 반영
      _fetchMe();      // 접속중인 사용자 정보 로드 (name만 사용)
    });
  }

  Future<void> _fetchMe() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _displayName = (j['name'] ?? j['username'] ?? '').toString();
        });
      }
    } catch (_) {/* ignore */}
  }

  // ===== 파싱 유틸 =====
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
  String _str(dynamic v) => (v ?? '').toString();

  int _scoreOf(Map<String, dynamic> j) =>
      _toInt(j['totalScore'] ?? j['score'] ?? j['riskScore']);

  String _typeOf(Map<String, dynamic> j) =>
      _str(j['type'] ?? j['typeName'] ?? j['profileType'] ?? j['riskType']);

  String _gradeOf(Map<String, dynamic> j) =>
      _str(j['grade'] ?? j['riskGrade'] ?? j['riskGradeName']);

  String _descOf(Map<String, dynamic> j, String type) {
    final fromServer = _str(
      j['typeDescription'] ?? j['description'] ?? j['desc'] ?? j['profile'],
    );
    if (fromServer.trim().isNotEmpty) return fromServer;

    const fallback = {
      '안정형': '원금 손실을 최소화하며 예·적금 수준의 안정적 수익을 선호합니다.',
      '안정추구형': '다소의 손실 가능성을 감내하고 예·적금보다 다소 높은 수익을 기대합니다.',
      '위험중립형': '위험과 수익의 균형을 중시하며 일정 수준의 손실을 감수할 수 있습니다.',
      '적극투자형': '높은 수익을 위해 비교적 큰 변동성도 수용할 수 있습니다.',
      '공격투자형': '높은 위험과 변동성을 감수하고서라도 고수익을 추구합니다.',
    };
    return fallback[type] ?? '투자성향에 맞는 위험·수익 균형을 지향합니다.';
  }

  // === 버블 인덱스 정확 매칭: 문자열 정규화 기반 ===
  String _normKey(String s) {
    // 공백/특정 접미어 제거 + 소문자
    final t = s
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('투자형', '')
        .replaceAll('투자', '')
        .replaceAll('형', '')
        .toLowerCase();
    return t;
  }

  int _typeIndexByServer(String typeRaw, Map<String, dynamic> j) {
    // 1) 직접 문자열 매핑
    final key = _normKey(typeRaw);
    const map = {
      // 한글
      '안정': 0,
      '안정추구': 1,
      '위험중립': 2,
      '중립': 2,
      '적극': 3,
      '적극투자': 3,
      '공격': 4,
      '공격투자': 4,
      // 영문
      'conservative': 0,
      'stable': 0,
      'moderateconservative': 1,
      'stableplus': 1,
      'neutral': 2,
      'balanced': 2,
      'aggressive': 3,
      'veryaggressive': 4,
    };
    if (map.containsKey(key)) return map[key]!;

    // 2) 코드 매핑 (A1/A2/B0/B1/B2)
    final code = _str(j['typeCode'] ?? j['profileCode']).toLowerCase();
    const codeMap = {'a1': 0, 'a2': 1, 'b0': 2, 'b1': 3, 'b2': 4};
    if (codeMap.containsKey(code)) return codeMap[code]!;

    // 3) 숫자 등급 매핑(1~5)
    final gradeNum = _toInt(j['gradeNum'] ?? j['riskGradeNum']);
    if (gradeNum >= 1 && gradeNum <= 5) return gradeNum - 1;

    // 4) 최종 안전값: 중립
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final score = _scoreOf(_data);
    final type  = _typeOf(_data);
    final grade = _gradeOf(_data);
    final desc  = _descOf(_data, type);
    final selectedIdx = _typeIndexByServer(grade, _data);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('분석 결과'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // 뒤로가기 화살표 제거
      ),
      body: SafeArea(
        child: Column(
          children: [
            const StepHeader(bigStep: 3, showBigProgress: false),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final isNarrow = c.maxWidth < 720;

                  // 게이지: 반응형 사이즈
                  final usableWidth = c.maxWidth - 48;
                  final gaugeSize = math.min(
                    260.0,
                    math.max(160.0, usableWidth * (isNarrow ? 0.62 : 0.45)),
                  );

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      24, 12, 24,
                      24 + 52 + 16, // 하단 버튼 높이만큼 여유
                    ),
                    children: [
                      SizedBox(height: 25,),
                      // ===== 상단 타이틀: 이름 강조 =====
                      Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _displayName.isEmpty ? '' : _displayName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 30,
                                  color: AppColors.fontColor,
                                ),
                              ),
                              TextSpan(
                                text: _displayName.isEmpty ? '투자성향 결과' : '  님의 투자성향',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  color: AppColors.fontColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ===== 투자유형 카드: 결과 유형 이름 + 설명 (+ 등급 칩) =====
                      _TypeCard(
                        typeName: (type.isEmpty) ? '투자유형' : type,
                        description: desc,
                        grade: grade,
                      ),

                      const SizedBox(height: 30),


                      // ===== 유형 버블 (강조) =====
                      _TypeRailEmphasis(selectedIndex: selectedIdx),

                      const SizedBox(height: 80),
                      RepaintBoundary(
                        child: ScoreGauge(
                          score: score,
                          maxScore: widget.maxScore,
                          color: AppColors.primaryBlue,
                          size: gaugeSize,
                          thickness: 24,
                          gradientColors: const [Color(0xFF9DBEFF), Color(0xFF0064FF), Color(0xFF003FAD)],
                          gradientStops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScaffold()),
                            (_) => false,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text('완료', style: TextStyle(fontSize: 17),),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== 타입 카드 ===================== */

class _TypeCard extends StatelessWidget {
  final String typeName;
  final String description;
  final String grade;

  const _TypeCard({
    required this.typeName,
    required this.description,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppColors.fontColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 결과 유형 이름 (크게)
          Text(
            grade,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.fontColor,
            ),
          ),
          const SizedBox(height: 15),
          // 설명
          Text(
            description,
            style: TextStyle(
              color: base.withOpacity(.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F6FD),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E9FB)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/* ============ 유형 레일(강조형, 스크롤 없음) ============ */

class _TypeRailEmphasis extends StatelessWidget {
  final int selectedIndex; // 0~4
  const _TypeRailEmphasis({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    const labels = ['안정형', '안정추구형', '위험중립형', '적극투자형', '공격투자형'];

    return LayoutBuilder(builder: (context, c) {
      final slotW = (c.maxWidth / labels.length);
      double base = (slotW * 0.68).clamp(56.0, 76.0);
      double neigh = (slotW * 0.78).clamp(base + 2, 84.0);
      double pick = (slotW * 0.88).clamp(neigh + 2, 92.0);

      const baseOffset = 16.0;
      const neighOffset = 8.0;
      const pickOffset = 0.0;

      return SizedBox(
        height: pick + baseOffset + 10,
        child: Row(
          children: List.generate(labels.length, (i) {
            final dist = (i - selectedIndex).abs();
            final bool isPick = dist == 0;
            final bool isNeigh = dist == 1;

            final size = isPick ? pick : (isNeigh ? neigh : base);
            final dy = isPick ? pickOffset : (isNeigh ? neighOffset : baseOffset);

            return SizedBox(
              width: slotW,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: Offset(0, dy),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: isPick ? AppColors.primaryBlue : const Color(0xFFEAF0FE),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (isPick)
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(.28),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isPick ? Colors.white : const Color(0xFF3C4A77),
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    });
  }
}
