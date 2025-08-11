import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart'; // AppColors.primaryBlue 사용

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FundJoinSuccess(),
  ));
}

class FundJoinSuccess extends StatefulWidget {
  const FundJoinSuccess({super.key});

  @override
  State<FundJoinSuccess> createState() => _FundJoinSuccessState();
}

class _FundJoinSuccessState extends State<FundJoinSuccess>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  Color get blue => AppColors
      .primaryBlue; // 대체: const Color(0xFF0064FF); // Toss Blue 계열

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _rotation = Tween<double>(begin: 0.0, end: 2.0 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 스샷 텍스트
  final String startInText = '2일 뒤';
  final String appliedDate = '25.08.05';
  final String amountFixDate = '25.08.07 예정';
  final String investStartDate = '25.08.07 예정';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 핑크 방지
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        title: const Text(
          '펀드 가입',
          style: TextStyle(
            fontSize: 20, // 스샷 대비 크기 고정
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0), // 좌우 여백 20
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
                    radius: 28, // 지름 56(px) 정도 느낌
                    backgroundColor: blue,
                    child: const Icon(Icons.check, color: Colors.white, size: 30),
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // "펀드투자가 2일 뒤에 시작됩니다"
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 26, // 문장 크기
                      height: 1.4,
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(
                        text: '펀드투자가\n',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: startInText,
                        style: TextStyle(
                          color: blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 30
                        ),
                      ),
                      const TextSpan(
                        text: '에 시작됩니다',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // 타임라인
              _Timeline(
                blue: blue,
                items: const [
                  TimelineItem(
                    stepNumber: 1,
                    title: '투자신청',
                    rightText: '25.08.05',
                    status: TimelineStatus.done,
                  ),
                  TimelineItem(
                    stepNumber: 2,
                    title: '금액확정',
                    rightText: '25.08.07 예정',
                    status: TimelineStatus.pending,
                  ),
                  TimelineItem(
                    stepNumber: 3,
                    title: '투자시작',
                    rightText: '25.08.07 예정',
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
                  onPressed: () => Navigator.pop(context),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
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
          blue: Color(0xFF00BBFF),
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
                  height: 40, // 스샷 길이 맞춤
                  margin: const EdgeInsets.only(top: 6, bottom: 0),
                  color: const Color(0xFFE5E7EB), // 연회색 라인
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
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
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
                color: Color(0xFF6B7280), // 회색(문구)
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
    const double outer = 28; // 외곽 원
    const double inner = 28; // 내부 원

    if (done) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              color: Color(0xFF00BBFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
        ],
      );
    }

    return Container(
      width: outer,
      height: outer,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6), // 회색 배경
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFFBFC4CA), // 연회색 숫자
          ),
        ),
      ),
    );
  }
}




