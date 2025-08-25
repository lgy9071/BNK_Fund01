import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:mobile_front/screens/my_finance_screen.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/constants/api.dart'; // ApiConfig.joinSummaryByTxId 사용

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    // 데모용: 임시 txId 전달
    home: FundJoinSuccess(transactionId: 123),
  ));
}

/// 서버 응답 예시
/// {
///   "transactionId": 101,
///   "tradeDate": "2025-08-05",
///   "navDate": "2025-08-07",
///   "processedAt": "2025-08-07",
///   "settlementDate": "2025-08-29"
/// }
class JoinSummary {
  final int transactionId;
  final DateTime tradeDate;     // D (투자신청)
  final DateTime navDate;       // T (금액확정)
  final DateTime processedAt;   // 체결일(투자시작)
  final DateTime settlementDate;

  JoinSummary({
    required this.transactionId,
    required this.tradeDate,
    required this.navDate,
    required this.processedAt,
    required this.settlementDate,
  });

  factory JoinSummary.fromJson(Map<String, dynamic> j) {
    DateTime parse(String k) => DateTime.parse(j[k]); // "yyyy-MM-dd"
    return JoinSummary(
      transactionId: j['transactionId'] is int
          ? j['transactionId'] as int
          : int.parse(j['transactionId'].toString()),
      tradeDate: parse('tradeDate'),
      navDate: parse('navDate'),
      processedAt: parse('processedAt'),
      settlementDate: parse('settlementDate'),
    );
  }
}

class FundJoinSuccess extends StatefulWidget {
  final int transactionId; // ✅ 가입 API에서 받은 txId만 필요
  const FundJoinSuccess({super.key, required this.transactionId});

  @override
  State<FundJoinSuccess> createState() => _FundJoinSuccessState();
}

class _FundJoinSuccessState extends State<FundJoinSuccess>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late Future<JoinSummary> _future;

  Color get blue => AppColors.primaryBlue; // 예: Color(0xFF0064FF)

  // 날짜 포맷: "yy.MM.dd"
  final _fmt = DateFormat('yy.MM.dd');

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _rotation = Tween<double>(begin: 0.0, end: 2.0 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();

    _future = _fetchJoinSummary(widget.transactionId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// DB에서 날짜 4종 받아오기 (특정 거래건)
  Future<JoinSummary> _fetchJoinSummary(int transactionId) async {
    final uri = Uri.parse(ApiConfig.joinSummaryByTxId(transactionId));

    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'accessToken');

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token', // ✅ 추가
      },
    );

    if (res.statusCode != 200) {
      throw Exception('서버 통신 실패 (${res.statusCode})');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return JoinSummary.fromJson(body);
  }

  /// 상단 "N일 뒤" / "오늘" / "시작되었습니다" 문구
  String _remainingText(DateTime nowDate, DateTime processedAt) {
    final today = DateTime(nowDate.year, nowDate.month, nowDate.day);
    final start = DateTime(processedAt.year, processedAt.month, processedAt.day);
    final diff = start.difference(today).inDays;
    if (diff < 0) return '시작되었습니다';
    if (diff == 0) return '오늘';
    return '$diff일 뒤';
  }

  /// 타임라인 오른쪽 날짜 포맷 + "예정" 꼬리표
  String _dateWithPlanned(DateTime date) {
    final today = DateTime.now();
    final onlyDate = DateTime(date.year, date.month, date.day);
    final onlyToday = DateTime(today.year, today.month, today.day);
    final d = _fmt.format(date);
    return onlyDate.isAfter(onlyToday) ? '$d 예정' : d;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경 화이트
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        title: const Text(
          '펀드 가입',
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<JoinSummary>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorView(
                message: '가입 정보를 불러오지 못했습니다.\n${snap.error}',
                onRetry: () {
                  setState(() {
                    _future = _fetchJoinSummary(widget.transactionId);
                  });
                },
              );
            }

            final data = snap.data!;
            final nowDate = DateTime.now();
            final remainText = _remainingText(nowDate, data.processedAt);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 체크 원
                  Center(
                    child: AnimatedBuilder(
                      animation: _rotation,
                      builder: (context, child) {
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(_rotation.value),
                          child: child,
                        );
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: blue,
                        child: const Icon(Icons.check, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // "펀드투자가 N일 뒤/오늘/시작되었습니다 ..."
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 26, height: 1.4, color: Colors.black,
                        ),
                        children: [
                          const TextSpan(
                            text: '펀드투자가\n',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: remainText,
                            style: TextStyle(
                              color: blue, fontWeight: FontWeight.w800, fontSize: 30,
                            ),
                          ),
                          TextSpan(
                            text: (remainText == '시작되었습니다') ? '' : '에 시작됩니다',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // 타임라인 (D / T / 체결일)
                  _Timeline(
                    blue: blue,
                    items: [
                      TimelineItem(
                        stepNumber: 1,
                        title: '투자신청',
                        rightText: _fmt.format(data.tradeDate), // D
                        status: TimelineStatus.done,
                      ),
                      TimelineItem(
                        stepNumber: 2,
                        title: '금액확정',
                        rightText: _dateWithPlanned(data.navDate), // T
                        status: TimelineStatus.pending,
                      ),
                      TimelineItem(
                        stepNumber: 3,
                        title: '투자시작',
                        rightText: _dateWithPlanned(data.processedAt), // 체결일
                        status: TimelineStatus.pending,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 하단 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MyFinanceScreen()),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===== 에러뷰 =====
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('다시 시도'))
        ],
      ),
    );
  }
}

// ===== 타임라인 구성 =====
enum TimelineStatus { done, pending }

class TimelineItem {
  final int stepNumber;
  final String title;
  final String rightText;
  final TimelineStatus status;
  const TimelineItem({
    required this.stepNumber,
    required this.title,
    required this.rightText,
    required this.status,
  });
}

class _Timeline extends StatelessWidget {
  final List<TimelineItem> items;
  final Color blue;
  const _Timeline({required this.items, required this.blue});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final drawLineBelow = i != items.length - 1;
        return _TimelineRow(
          blue: blue,
          item: item,
          drawLineBelow: drawLineBelow,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineItem item;
  final bool drawLineBelow;
  final Color blue;
  const _TimelineRow({
    required this.item,
    required this.drawLineBelow,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == TimelineStatus.done;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인디케이터 + 세로 라인
          Column(
            children: [
              _StepIndicator(
                number: item.stepNumber,
                done: isDone,
                blue: blue,
              ),
              if (drawLineBelow)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.only(top: 6, bottom: 0),
                  color: const Color(0xFFE5E7EB),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 좌측 텍스트
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black,
                ),
              ),
            ),
          ),
          // 우측 날짜
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              item.rightText,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int number;
  final bool done;
  final Color blue;
  const _StepIndicator({
    required this.number,
    required this.done,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    const double sz = 28;
    if (done) {
      return Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(color: blue, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 18),
      );
    }
    return Container(
      width: sz,
      height: sz,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFBFC4CA),
          ),
        ),
      ),
    );
  }
}
